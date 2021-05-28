//
//  PolicyCompiler.m
//  Stimulator
//
//  Created by Sophia Wisdom on 5/9/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "PolicyCompiler.h"
#include "../libclang/Index.h"

@implementation PolicyCompiler {
    id<PolicyObserver> _obj;
    NSString * _code;
    NSThread *_compiler_thread;
    mach_port_t _thread_port;
    _Atomic bool _dirty;
    NSString *_tempdir;
    NSString *_tempfile;
    
    CXTranslationUnit _cur_tu;
    CXIndex _index;
}

- (instancetype)initWithObject:(id<PolicyObserver>)obj;
{
    if (self = [super init]) {
        _obj = obj;
        _tempdir = NSTemporaryDirectory();
        _tempfile = [NSString stringWithFormat:@"%@/placeholder.c", _tempdir];
        [[NSFileManager defaultManager] createFileAtPath:_tempfile contents:nil attributes:nil];
        
        _index = clang_createIndex(0, 0);

        _compiler_thread = [[NSThread alloc] initWithTarget:self selector:@selector(run_thread) object:nil];
        [_compiler_thread start];
    }
    return self;
}

- (void)run_thread {
    _thread_port = mach_thread_self();
    NSString *last_code = nil;
    while (1) {
        if (last_code == _code) {
            thread_suspend(_thread_port);
        }
        last_code = _code;

        // Now we compile last_code to a policy function


        [_obj setCompiledPolicy:default_policy];
    }
}

- (NSArray<Diagnostic *> *)setCode:(NSString *)code {
    // ANALYZE
    struct CXUnsavedFile *file = calloc(1, sizeof(struct CXUnsavedFile));
    file -> Contents = [_code UTF8String];
    file -> Length = strlen(file -> Contents);
    file -> Filename = [_tempfile UTF8String];

    // TODO: clang_reparse? Could give perf improvement.
    // Also: precompiled headers?
    if (_cur_tu) {
        clang_disposeTranslationUnit(_cur_tu);
    }

    const char *args[] = {
        "-I."
    };
    int resp = clang_parseTranslationUnit2(_index, NULL, args, sizeof(args)/sizeof(*args), file, 1, CXTranslationUnit_None, &_cur_tu);
    if (resp != 0) {
        printf("clang ParseTranslationUnit2 failed, error code %d\n", resp);
        return NULL;
    }
    
    bool compilable = true;

    int diagnosticCount = clang_getNumDiagnostics(_cur_tu);
    NSMutableArray<Diagnostic *> *diagnostics = [[NSMutableArray alloc] initWithCapacity:diagnosticCount];
    for (unsigned int i = 0; i < diagnosticCount; i++) {
        CXDiagnostic diagnostic = clang_getDiagnostic(_cur_tu, i);
        Diagnostic *diagnostic_obj = [[Diagnostic alloc] init];

        diagnostic_obj.severity = clang_getDiagnosticSeverity(diagnostic);
        if (clang_getDiagnosticSeverity(diagnostic) == CXDiagnostic_Error || clang_getDiagnosticSeverity(diagnostic) == CXDiagnostic_Fatal) {
            compilable = false;
        }
        CXString text = clang_getDiagnosticSpelling(diagnostic); // consider clang_formatDiagnostic
        diagnostic_obj.str = [NSString stringWithUTF8String:clang_getCString(text)];
        clang_disposeString(text);

        CXSourceLocation loc = clang_getDiagnosticLocation(diagnostic);
        unsigned int line = 0;
        unsigned int column = 0;
        clang_getSpellingLocation(loc, NULL, &line, &column, NULL);
        diagnostic_obj.line = line;
        diagnostic_obj.column = column;
        
        [diagnostics addObject:diagnostic_obj];
        clang_disposeDiagnostic(diagnostic); // TODO: Is this necessary?
    }
    
    __block bool legit = true;
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(_cur_tu), ^enum CXChildVisitResult(CXCursor cursor, CXCursor parent) {
        // Don't allow any additional function declarations.
        // Don't allow any return statements that don't return one of Right or Top
        // Don't allow any writes to memory, including to the struct simul
        // Don't allow any function calls other than the ones we expose
        // Function should as a whole be "pure"
        if (0) {
            legit = false;
            Diagnostic *diagnostic_obj = [[Diagnostic alloc] init];
            diagnostic_obj.column = 5;
            diagnostic_obj.line = 5;
            diagnostic_obj.severity = CXDiagnostic_Error;
            diagnostic_obj.str = @"Return statement not one of Right or Top.";
            [diagnostics addObject:diagnostic_obj];
        }
        return CXChildVisit_Recurse;
    });
    
    if (compilable && legit)  {
        _code = code;
        thread_resume(_thread_port); // begin compiling the code into a policy
    }

    return diagnostics;
}

- (void)dealloc
{
    mach_port_deallocate(mach_task_self(), _thread_port);
    if (_cur_tu) {
        clang_disposeTranslationUnit(_cur_tu);
    }
    clang_disposeIndex(_index);
}

@end
