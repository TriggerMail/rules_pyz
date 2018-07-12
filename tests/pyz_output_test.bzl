
def pyz_output_test(name, pyz_binary, expected_output, extra_arg="", expect_failure=False, tags=[]):
    args=[
        "--command=$(location " + pyz_binary + ")",
        "--zip-command=$(location " + pyz_binary + "_exezip)",
        "--expected-output='" + expected_output + "'",
    ]
    if expect_failure:
        args.append("--expect-failure")
    if extra_arg != "":
        args.append("--extra-arg=" + extra_arg)
    return native.sh_test(
        name=name,
        srcs=["command_output_tester.py"],
        data=[pyz_binary, pyz_binary + "_exezip"],
        args=args,
        tags=tags,
    )
