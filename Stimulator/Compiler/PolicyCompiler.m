//
//  PolicyCompiler.m
//  Stimulator
//
//  Created by Sophia Wisdom on 5/9/21.
//  Copyright © 2021 Sophia Wisdom. All rights reserved.
//

#import "PolicyCompiler.h"
#include "Index.h"

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

- (NSArray<Diagnostics>)setCode:(NSString *)code {
    if ([code isEqualToString:_code]) {
        return;
    }
    // ANALYZE
    struct CXUnsavedFile *file = calloc(1, sizeof(struct CXUnsavedFile));
    file -> Contents = [_code UTF8String];
    file -> Length = strlen(file -> Contents);
    file -> Filename = [_tempfile UTF8String];
    
    // TODO: clang_reparse? Could give perf improvement.
    // Also: precompiled headers?
    const char *args[] = {
        "-I."
    };
    int resp = clang_parseTranslationUnit2(_index, NULL, args, sizeof(args)/sizeof(*args), file, 1, CXTranslationUnit_None, &_cur_tu);
    if (resp != 0) {
        printf("clang ParseTranslationUnit2 failed, error code %d\n", resp);
        return;
    }

    int diagnosticCount = clang_getNumDiagnostics(_cur_tu);
    NSMutableArray<NSString *> *diagnostics = [[NSMutableArray alloc] initWithCapacity:diagnosticCount];
    for (unsigned int i = 0; i < diagnosticCount; i++) {
        CXDiagnostic diagnostic = clang_getDiagnostic(_cur_tu, i);
        clang_getDiagnosticSeverity(diagnostic);
        CXSourceLocation loc = clang_getDiagnosticLocation(diagnostic);
        [diagnostics addObject:<#(nonnull NSString *)#>]
        
    }

    _code = code;
    thread_resume(_thread_port);
}

- (void)dealloc
{
    mach_port_deallocate(mach_task_self(), _thread_port);
}

@end
