"""Tests for compiler options processing functions."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//test:utils.bzl", "stringify_dict")

# buildifier: disable=bzl-visibility
load("//xcodeproj/internal:opts.bzl", "testable")

process_compiler_opts = testable.process_compiler_opts

def _process_compiler_opts_test_impl(ctx):
    env = unittest.begin(ctx)

    build_settings = {}
    search_paths = process_compiler_opts(
        conlyopts = ctx.attr.conlyopts,
        cxxopts = ctx.attr.cxxopts,
        swiftcopts = ctx.attr.swiftcopts,
        build_mode = ctx.attr.build_mode,
        cpp_fragment = _cpp_fragment_stub(ctx.attr.cpp_fragment),
        package_bin_dir = ctx.attr.package_bin_dir,
        build_settings = build_settings,
    )
    string_build_settings = stringify_dict(build_settings)
    json_search_paths = json.encode(search_paths)

    expected_build_settings = {
        "DEBUG_INFORMATION_FORMAT": "",
        "ENABLE_STRICT_OBJC_MSGSEND": "True",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "SWIFT_OBJC_INTERFACE_HEADER_NAME": "",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        "SWIFT_VERSION": "5.0",
    }
    expected_build_settings.update(ctx.attr.expected_build_settings)

    if (ctx.attr.expected_build_settings.get("DEBUG_INFORMATION_FORMAT", "") ==
        "None"):
        expected_build_settings.pop("DEBUG_INFORMATION_FORMAT")

    asserts.equals(
        env,
        expected_build_settings,
        string_build_settings,
        "build_settings",
    )

    asserts.equals(
        env,
        ctx.attr.expected_search_paths,
        json_search_paths,
        "search_paths",
    )

    return unittest.end(env)

process_compiler_opts_test = unittest.make(
    impl = _process_compiler_opts_test_impl,
    attrs = {
        "build_mode": attr.string(mandatory = True),
        "conlyopts": attr.string_list(mandatory = True),
        "cxxopts": attr.string_list(mandatory = True),
        "expected_build_settings": attr.string_dict(mandatory = True),
        "expected_search_paths": attr.string(mandatory = True),
        "cpp_fragment": attr.string_dict(mandatory = False),
        "package_bin_dir": attr.string(mandatory = True),
        "swiftcopts": attr.string_list(mandatory = True),
    },
)

def _cpp_fragment(*, apple_generate_dsym):
    return {
        "apple_generate_dsym": json.encode(apple_generate_dsym),
    }

def _cpp_fragment_stub(dict):
    if not dict:
        return struct(
            apple_generate_dsym = True,
        )
    return struct(
        apple_generate_dsym = json.decode(dict["apple_generate_dsym"]),
    )

def process_compiler_opts_test_suite(name):
    """Test suite for `process_compiler_opts`.

    Args:
        name: The base name to be used in things created by this macro. Also the
            name of the test suite.
    """
    test_names = []

    def _add_test(
            *,
            name,
            expected_build_settings,
            expected_search_paths = {
                "quote_includes": [],
                "includes": [],
                "system_includes": [],
                "framework_includes": [],
            },
            conlyopts = [],
            cxxopts = [],
            swiftcopts = [],
            build_mode = "bazel",
            cpp_fragment = None,
            package_bin_dir = ""):
        test_names.append(name)
        process_compiler_opts_test(
            name = name,
            conlyopts = conlyopts,
            cxxopts = cxxopts,
            swiftcopts = swiftcopts,
            build_mode = build_mode,
            cpp_fragment = cpp_fragment,
            package_bin_dir = package_bin_dir,
            expected_build_settings = stringify_dict(expected_build_settings),
            expected_search_paths = json.encode(expected_search_paths),
            timeout = "short",
        )

    # Base

    _add_test(
        name = "{}_swift_integration_bazel".format(name),
        build_mode = "bazel",
        swiftcopts = [
            "-target",
            "arm64-apple-ios15.0-simulator",
            "-sdk",
            "__BAZEL_XCODE_SDKROOT__",
            "-F__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
            "-F__BAZEL_XCODE_SDKROOT__/Developer/Library/Frameworks",
            "-I__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
            "-emit-object",
            "-output-file-map",
            "bazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin/examples/ExampleUITests/ExampleUITests.library.output_file_map.json",
            "-Xfrontend",
            "-no-clang-module-breadcrumbs",
            "-emit-module-path",
            "bazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin/examples/ExampleUITests/ExampleUITests.swiftmodule",
            "-DDEBUG",
            "-Onone",
            "-Xfrontend",
            "-serialize-debugging-options",
            "-enable-testing",
            "-application-extension",
            "weird",
            "-gline-tables-only",
            "-Xwrapped-swift=-debug-prefix-pwd-is-dot",
            "-Xwrapped-swift=-ephemeral-module-cache",
            "-Xcc",
            "-iquote.",
            "-Xcc",
            "-iquotebazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin",
            "-Xfrontend",
            "-color-diagnostics",
            "-enable-batch-mode",
            "-unhandled",
            "-module-name",
            "ExampleUITests",
            "-parse-as-library",
            "-Xcc",
            "-O0",
            "-Xcc",
            "-DDEBUG=1",
            "examples/xcode_like/ExampleUITests/ExampleUITests.swift",
            "examples/xcode_like/ExampleUITests/ExampleUITestsLaunchTests.swift",
        ],
        expected_build_settings = {
            "ENABLE_TESTABILITY": "True",
            "OTHER_SWIFT_FLAGS": """\
-application-extension \
weird \
-Xcc \
-iquote. \
-Xcc \
-iquotebazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin \
-unhandled \
-Xcc \
-O0 \
-Xcc \
-DDEBUG=1\
""",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        },
        expected_search_paths = {
            "quote_includes": [
                ".",
                "bazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin",
            ],
            "includes": [],
            "system_includes": [],
            "framework_includes": [],
        },
    )

    _add_test(
        name = "{}_swift_integration_xcode".format(name),
        build_mode = "xcode",
        swiftcopts = [
            "-target",
            "arm64-apple-ios15.0-simulator",
            "-sdk",
            "__BAZEL_XCODE_SDKROOT__",
            "-F__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
            "-F__BAZEL_XCODE_SDKROOT__/Developer/Library/Frameworks",
            "-I__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
            "-emit-object",
            "-output-file-map",
            "bazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin/examples/ExampleUITests/ExampleUITests.library.output_file_map.json",
            "-Xfrontend",
            "-no-clang-module-breadcrumbs",
            "-emit-module-path",
            "bazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin/examples/ExampleUITests/ExampleUITests.swiftmodule",
            "-DDEBUG",
            "-Onone",
            "-Xfrontend",
            "-serialize-debugging-options",
            "-enable-testing",
            "-application-extension",
            "weird",
            "-gline-tables-only",
            "-Xwrapped-swift=-debug-prefix-pwd-is-dot",
            "-Xwrapped-swift=-ephemeral-module-cache",
            "-Xcc",
            "-iquote.",
            "-Xcc",
            "-iquotebazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin",
            "-Xfrontend",
            "-color-diagnostics",
            "-enable-batch-mode",
            "-unhandled",
            "-module-name",
            "ExampleUITests",
            "-parse-as-library",
            "-Xcc",
            "-O0",
            "-Xcc",
            "-DDEBUG=1",
            "examples/xcode_like/ExampleUITests/ExampleUITests.swift",
            "examples/xcode_like/ExampleUITests/ExampleUITestsLaunchTests.swift",
        ],
        expected_build_settings = {
            "ENABLE_TESTABILITY": "True",
            "OTHER_SWIFT_FLAGS": """\
-application-extension \
weird \
-Xcc \
-iquote. \
-Xcc \
-iquote$(PROJECT_DIR)/bazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin \
-unhandled \
-Xcc \
-O0 \
-Xcc \
-DDEBUG=1\
""",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        },
        expected_search_paths = {
            "quote_includes": [
                ".",
                "bazel-out/ios-sim_arm64-min15.0-applebin_ios-ios_sim_arm64-fastbuild-ST-4e6c2a19403f/bin",
            ],
            "includes": [],
            "system_includes": [],
            "framework_includes": [],
        },
    )

    _add_test(
        name = "{}_empty".format(name),
        conlyopts = [],
        cxxopts = [],
        swiftcopts = [],
        expected_build_settings = {},
    )

    # Skips

    ## C and C++
    # Anything with __BAZEL_XCODE_
    # -isysroot
    # -mios-simulator-version-min
    # -miphoneos-version-min
    # -mmacosx-version-min
    # -mtvos-simulator-version-min
    # -mtvos-version-min
    # -mwatchos-simulator-version-min
    # -mwatchos-version-min
    # -target

    ## Swift:
    # Anything with __BAZEL_XCODE_
    # -debug-prefix-map
    # -emit-module-path
    # -emit-object
    # -enable-batch-mode
    # -gline-tables-only
    # -module-name
    # -num-threads
    # -output-file-map
    # -parse-as-library
    # -sdk
    # -target
    # -Xwrapped-swift
    # Other things that end with ".swift", but don't start with "-"

    _add_test(
        name = "{}_skips_bazel".format(name),
        build_mode = "bazel",
        conlyopts = [
            "-mtvos-simulator-version-min=8.0",
            "-passthrough",
            "-isysroot",
            "other",
            "-mios-simulator-version-min=11.2",
            "-miphoneos-version-min=9.0",
            "-passthrough",
            "-mtvos-version-min=12.1",
            "-I__BAZEL_XCODE_SOMETHING_/path",
            "-mwatchos-simulator-version-min=10.1",
            "-passthrough",
            "-mwatchos-version-min=9.2",
            "-target",
            "ios",
            "-mmacosx-version-min=12.0",
            "-passthrough",
        ],
        cxxopts = [
            "-isysroot",
            "something",
            "-miphoneos-version-min=9.4",
            "-mmacosx-version-min=10.9",
            "-passthrough",
            "-mtvos-version-min=12.2",
            "-mwatchos-simulator-version-min=9.3",
            "-passthrough",
            "-mtvos-simulator-version-min=12.1",
            "-mwatchos-version-min=10.2",
            "-I__BAZEL_XCODE_BOSS_",
            "-target",
            "macos",
            "-passthrough",
            "-mios-simulator-version-min=14.0",
        ],
        swiftcopts = [
            "-output-file-map",
            "path",
            "-passthrough",
            "-debug-prefix-map",
            "__BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR",
            "-file-prefix-map",
            "__BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR",
            "-emit-module-path",
            "path",
            "-passthrough",
            "-Xfrontend",
            "-color-diagnostics",
            "-Xfrontend",
            "-import-underlying-module",
            "-emit-object",
            "-enable-batch-mode",
            "-vfsoverlay",
            "/Some/Path.yaml",
            "-vfsoverlay",
            "relative/Path.yaml",
            "-passthrough",
            "-gline-tables-only",
            "-sdk",
            "something",
            "-module-name",
            "name",
            "-passthrough",
            "-I__BAZEL_XCODE_SOMETHING_/path",
            "-num-threads",
            "6",
            "-passthrough",
            "-Ibazel-out/...",
            "-parse-as-library",
            "-passthrough",
            "-parse-as-library",
            "-Xfrontend",
            "-vfsoverlay",
            "-Xfrontend",
            "/Some/Path.yaml",
            "-Xfrontend",
            "-vfsoverlay",
            "-Xfrontend",
            "relative/Path.yaml",
            "-keep-me=something.swift",
            "reject-me.swift",
            "-Xfrontend",
            "-vfsoverlay/Some/Path.yaml",
            "-Xfrontend",
            "-vfsoverlayrelative/Path.yaml",
            "-target",
            "ios",
            "-Xcc",
            "-weird",
            "-Xcc",
            "-a=bazel-out/hi",
            "-Xwrapped-swift",
            "-passthrough",
        ],
        expected_build_settings = {
            "OTHER_CFLAGS": [
                "-passthrough",
                "-passthrough",
                "-passthrough",
                "-passthrough",
            ],
            "OTHER_CPLUSPLUSFLAGS": [
                "-passthrough",
                "-passthrough",
                "-passthrough",
            ],
            "OTHER_SWIFT_FLAGS": """\
-passthrough \
-passthrough \
-Xfrontend \
-import-underlying-module \
-vfsoverlay \
/Some/Path.yaml \
-vfsoverlay \
$(PROJECT_DIR)/relative/Path.yaml \
-passthrough \
-passthrough \
-I__BAZEL_XCODE_SOMETHING_/path \
-passthrough \
-Ibazel-out/... \
-passthrough \
-Xfrontend \
-vfsoverlay \
-Xfrontend \
/Some/Path.yaml \
-Xfrontend \
-vfsoverlay \
-Xfrontend \
$(PROJECT_DIR)/relative/Path.yaml \
-keep-me=something.swift \
-Xfrontend \
-vfsoverlay/Some/Path.yaml \
-Xfrontend \
-vfsoverlay$(PROJECT_DIR)/relative/Path.yaml \
-Xcc \
-weird \
-Xcc \
-a=bazel-out/hi \
-passthrough\
""",
        },
        expected_search_paths = {
            "quote_includes": [],
            "includes": ["__BAZEL_XCODE_SOMETHING_/path", "__BAZEL_XCODE_BOSS_"],
            "system_includes": [],
            "framework_includes": [],
        },
    )

    _add_test(
        name = "{}_skips_xcode".format(name),
        build_mode = "xcode",
        conlyopts = [
            "-mtvos-simulator-version-min=8.0",
            "-passthrough",
            "-isysroot",
            "other",
            "-mios-simulator-version-min=11.2",
            "-miphoneos-version-min=9.0",
            "-passthrough",
            "-mtvos-version-min=12.1",
            "-I__BAZEL_XCODE_SOMETHING_/path",
            "-mwatchos-simulator-version-min=10.1",
            "-passthrough",
            "-mwatchos-version-min=9.2",
            "-target",
            "ios",
            "-mmacosx-version-min=12.0",
            "-passthrough",
        ],
        cxxopts = [
            "-isysroot",
            "something",
            "-miphoneos-version-min=9.4",
            "-mmacosx-version-min=10.9",
            "-passthrough",
            "-mtvos-version-min=12.2",
            "-mwatchos-simulator-version-min=9.3",
            "-passthrough",
            "-mtvos-simulator-version-min=12.1",
            "-mwatchos-version-min=10.2",
            "-I__BAZEL_XCODE_BOSS_",
            "-target",
            "macos",
            "-passthrough",
            "-mios-simulator-version-min=14.0",
        ],
        swiftcopts = [
            "-output-file-map",
            "path",
            "-passthrough",
            "-debug-prefix-map",
            "__BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR",
            "-file-prefix-map",
            "__BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR",
            "-emit-module-path",
            "path",
            "-passthrough",
            "-Xfrontend",
            "-color-diagnostics",
            "-Xfrontend",
            "-import-underlying-module",
            "-emit-object",
            "-enable-batch-mode",
            "-passthrough",
            "-gline-tables-only",
            "-sdk",
            "something",
            "-module-name",
            "name",
            "-passthrough",
            "-I__BAZEL_XCODE_SOMETHING_/path",
            "-num-threads",
            "6",
            "-passthrough",
            "-Ibazel-out/...",
            "-parse-as-library",
            "-passthrough",
            "-parse-as-library",
            "-keep-me=something.swift",
            "reject-me.swift",
            "-target",
            "ios",
            "-Xcc",
            "-weird",
            "-Xcc",
            "-a=bazel-out/hi",
            "-Xwrapped-swift",
            "-passthrough",
        ],
        expected_build_settings = {
            "OTHER_CFLAGS": [
                "-passthrough",
                "-passthrough",
                "-passthrough",
                "-passthrough",
            ],
            "OTHER_CPLUSPLUSFLAGS": [
                "-passthrough",
                "-passthrough",
                "-passthrough",
            ],
            "OTHER_SWIFT_FLAGS": """\
-passthrough \
-passthrough \
-Xfrontend \
-import-underlying-module \
-passthrough \
-passthrough \
-I$(PROJECT_DIR)/__BAZEL_XCODE_SOMETHING_/path \
-passthrough \
-I$(PROJECT_DIR)/bazel-out/... \
-passthrough \
-keep-me=something.swift \
-Xcc \
-weird \
-Xcc \
-a=bazel-out/hi \
-passthrough\
""",
        },
        expected_search_paths = {
            "quote_includes": [],
            "includes": ["__BAZEL_XCODE_SOMETHING_/path", "__BAZEL_XCODE_BOSS_"],
            "system_includes": [],
            "framework_includes": [],
        },
    )

    # Specific Xcode build settings

    ## DEBUG_INFORMATION_FORMAT

    _add_test(
        name = "{}_all-debug-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = True),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
        },
    )

    _add_test(
        name = "{}_all-debug-no-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "dwarf",
        },
    )

    _add_test(
        name = "{}_c-debug-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = True),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
        },
    )

    _add_test(
        name = "{}_c-debug-no-dsym".format(name),
        conlyopts = ["-g"],
        cxxopts = ["-g"],
        swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "dwarf",
        },
    )

    _add_test(
        name = "{}_conly-debug".format(name),
        conlyopts = ["-g"],
        cxxopts = [],
        swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "",
            "OTHER_CFLAGS": ["-g"],
        },
    )

    _add_test(
        name = "{}_cxx-debug".format(name),
        conlyopts = [],
        cxxopts = ["-g"],
        swiftcopts = [],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "",
            "OTHER_CPLUSPLUSFLAGS": ["-g"],
        },
    )

    _add_test(
        name = "{}_swift-debug-dsym".format(name),
        conlyopts = [],
        cxxopts = [],
        swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = True),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": None,
        },
    )

    _add_test(
        name = "{}_swift-debug-no-dsym".format(name),
        conlyopts = [],
        cxxopts = [],
        swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "dwarf",
        },
    )

    _add_test(
        name = "{}_swift-and-c-debug".format(name),
        conlyopts = ["-g"],
        cxxopts = [],
        swiftcopts = ["-g"],
        cpp_fragment = _cpp_fragment(apple_generate_dsym = False),
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "",
            "OTHER_CFLAGS": ["-g"],
            "OTHER_SWIFT_FLAGS": "-g",
        },
    )

    ## ENABLE_STRICT_OBJC_MSGSEND

    _add_test(
        name = "{}_enable_strict_objc_msgsend".format(name),
        conlyopts = ["-DOBJC_OLD_DISPATCH_PROTOTYPES=1"],
        expected_build_settings = {
            "DEBUG_INFORMATION_FORMAT": "",
            "ENABLE_STRICT_OBJC_MSGSEND": "False",
        },
    )

    ## ENABLE_TESTABILITY

    _add_test(
        name = "{}_swift_option-enable-testing".format(name),
        swiftcopts = ["-enable-testing"],
        expected_build_settings = {
            "ENABLE_TESTABILITY": "True",
        },
    )

    ## GCC_OPTIMIZATION_LEVEL

    _add_test(
        name = "{}_differing_gcc_optimization_level".format(name),
        conlyopts = ["-O0"],
        cxxopts = ["-O1"],
        expected_build_settings = {
            "OTHER_CFLAGS": ["-O0"],
            "OTHER_CPLUSPLUSFLAGS": ["-O1"],
        },
    )

    _add_test(
        name = "{}_differing_gcc_optimization_level_common_first".format(name),
        conlyopts = ["-O1", "-O0"],
        cxxopts = ["-O1", "-O2"],
        expected_build_settings = {
            "GCC_OPTIMIZATION_LEVEL": "1",
            "OTHER_CFLAGS": ["-O0"],
            "OTHER_CPLUSPLUSFLAGS": ["-O2"],
        },
    )

    _add_test(
        name = "{}_multiple_gcc_optimization_levels".format(name),
        conlyopts = ["-O1", "-O0"],
        cxxopts = ["-O0", "-O1"],
        expected_build_settings = {
            "OTHER_CFLAGS": ["-O1", "-O0"],
            "OTHER_CPLUSPLUSFLAGS": ["-O0", "-O1"],
        },
    )

    _add_test(
        name = "{}_common_gcc_optimization_level".format(name),
        conlyopts = ["-O1"],
        cxxopts = ["-O1"],
        expected_build_settings = {
            "GCC_OPTIMIZATION_LEVEL": "1",
        },
    )

    ## GCC_PREPROCESSOR_DEFINITIONS

    _add_test(
        name = "{}_gcc_optimization_preprocessor_definitions".format(name),
        conlyopts = ["-DDEBUG", "-DDEBUG", "-DA=1", "-DZ=1", "-DB", "-DE"],
        cxxopts = ["-DDEBUG", "-DDEBUG", "-DA=1", "-DZ=2", "-DC", "-DE"],
        expected_build_settings = {
            "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG", "A=1"],
            "OTHER_CFLAGS": ["-DZ=1", "-DB", "-DE"],
            "OTHER_CPLUSPLUSFLAGS": ["-DZ=2", "-DC", "-DE"],
        },
    )

    ## SWIFT_ACTIVE_COMPILATION_CONDITIONS

    _add_test(
        name = "{}_defines".format(name),
        swiftcopts = [
            "-DDEBUG",
            "-DBAZEL",
            "-DDEBUG",
            "-DBAZEL",
        ],
        expected_build_settings = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG BAZEL",
        },
    )

    ## SWIFT_COMPILATION_MODE

    _add_test(
        name = "{}_multiple_swift_compilation_modes".format(name),
        swiftcopts = [
            "-wmo",
            "-no-whole-module-optimization",
        ],
        expected_build_settings = {
            "SWIFT_COMPILATION_MODE": "singlefile",
        },
    )

    _add_test(
        name = "{}_swift_option-incremental".format(name),
        swiftcopts = ["-incremental"],
        expected_build_settings = {
            "SWIFT_COMPILATION_MODE": "singlefile",
        },
    )

    _add_test(
        name = "{}_swift_option-whole-module-optimization".format(name),
        swiftcopts = ["-whole-module-optimization"],
        expected_build_settings = {
            "SWIFT_COMPILATION_MODE": "wholemodule",
        },
    )

    _add_test(
        name = "{}_swift_option-wmo".format(name),
        swiftcopts = ["-wmo"],
        expected_build_settings = {
            "SWIFT_COMPILATION_MODE": "wholemodule",
        },
    )

    _add_test(
        name = "{}_swift_option-no-whole-module-optimization".format(name),
        swiftcopts = ["-no-whole-module-optimization"],
        expected_build_settings = {
            "SWIFT_COMPILATION_MODE": "singlefile",
        },
    )

    ## SWIFT_OBJC_INTERFACE_HEADER_NAME

    _add_test(
        name = "{}_generated_header".format(name),
        swiftcopts = [
            "-emit-objc-header-path",
            "a/b/c/TestingUtils-Custom.h",
        ],
        package_bin_dir = "a/b",
        expected_build_settings = {
            "SWIFT_OBJC_INTERFACE_HEADER_NAME": "c/TestingUtils-Custom.h",
        },
    )

    ## SWIFT_OPTIMIZATION_LEVEL

    _add_test(
        name = "{}_multiple_swift_optimization_levels".format(name),
        swiftcopts = [
            "-Osize",
            "-Onone",
            "-O",
        ],
        expected_build_settings = {
            "SWIFT_OPTIMIZATION_LEVEL": "-O",
        },
    )

    _add_test(
        name = "{}_swift_option-Onone".format(name),
        swiftcopts = ["-Onone"],
        expected_build_settings = {
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        },
    )

    _add_test(
        name = "{}_swift_option-O".format(name),
        swiftcopts = ["-O"],
        expected_build_settings = {
            "SWIFT_OPTIMIZATION_LEVEL": "-O",
        },
    )

    _add_test(
        name = "{}_swift_option-Osize".format(name),
        swiftcopts = ["-Osize"],
        expected_build_settings = {
            "SWIFT_OPTIMIZATION_LEVEL": "-Osize",
        },
    )

    ## SWIFT_STRICT_CONCURRENCY

    _add_test(
        name = "{}_swift_option-strict-concurrency".format(name),
        swiftcopts = ["-strict-concurrency=targeted"],
        expected_build_settings = {
            "SWIFT_STRICT_CONCURRENCY": "targeted",
        },
    )

    ## SWIFT_VERSION

    _add_test(
        name = "{}_swift_option-swift-version".format(name),
        swiftcopts = ["-swift-version=42"],
        expected_build_settings = {
            "SWIFT_VERSION": "42",
        },
    )

    # Search Paths

    _add_test(
        name = "{}_search_paths".format(name),
        conlyopts = [
            "-iquote",
            "a/b/c",
            "-iquotea/b/c/d",
            "-Ix/y/z",
            "-I",
            "1/2/3",
            "-iquote",
            "0/9",
            "-isystem",
            "s1/s2",
            "-isystems1/s2/s3",
        ],
        cxxopts = [
            "-iquote",
            "y/z",
            "-iquotey/z/1",
            "-Ix/y/z",
            "-I",
            "aa/bb",
            "-isystem",
            "s3/s4",
            "-isystems3/s4/s5",
        ],
        swiftcopts = [
            "-Xcc",
            "-Ic/d/e",
            "-Xcc",
            "-iquote4/5",
            "-Xcc",
            "-isystems5/s6",
        ],
        expected_build_settings = {
            "OTHER_SWIFT_FLAGS": "-Xcc -Ic/d/e -Xcc -iquote4/5 -Xcc -isystems5/s6",
        },
        expected_search_paths = {
            "quote_includes": [
                "a/b/c",
                "a/b/c/d",
                "0/9",
                "y/z",
                "y/z/1",
                "4/5",
            ],
            "includes": [
                "x/y/z",
                "1/2/3",
                "aa/bb",
                "c/d/e",
            ],
            "system_includes": [
                "s1/s2",
                "s1/s2/s3",
                "s3/s4",
                "s3/s4/s5",
                "s5/s6",
            ],
            "framework_includes": [],
        },
    )

    # Test suite

    native.test_suite(
        name = name,
        tests = test_names,
    )
