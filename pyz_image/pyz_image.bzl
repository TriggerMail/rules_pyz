load("@io_bazel_rules_docker//container:container.bzl", "container_image")

ZIP_TO_TAR_LABEL = "@com_bluecore_rules_pyz//pyz_image:zip_to_tar.py"
BASE_PY2_CONTAINER_IMAGE = "@com_bluecore_rules_pyz//pyz_image:py2_image_base"
BASE_PY3_CONTAINER_IMAGE = "@com_bluecore_rules_pyz//pyz_image:py3_image_base"

def pyz2_image(name, binary, base=BASE_PY2_CONTAINER_IMAGE, entrypoint=None, **kwargs):
    binary_exezip = binary + "_exezip"
    outtar = name + "_binary.tar"
    native.genrule(
        name=name + "_zip_to_tar",
        srcs=[binary_exezip],
        outs=[outtar],
        cmd="$(location {zip_to_tar_label}) $(location {binary_exezip}) $(location {outtar}) --add_prefix_dir=pyz_binary".format(
            zip_to_tar_label=ZIP_TO_TAR_LABEL,
            binary_exezip=binary_exezip,
            outtar=outtar),
        tools = [ZIP_TO_TAR_LABEL],
    )

    entrypoint = entrypoint or ["python2.7", "/pyz_binary"]
    container_image(
        name=name,
        base=base,
        tars=[outtar],
        entrypoint = entrypoint,
        legacy_run_behavior = False,
        **kwargs
    )


def pyz3_image(name, binary, base=BASE_PY3_CONTAINER_IMAGE, entrypoint=["python3", "/pyz_binary"], **kwargs):
    return pyz2_image(name, binary, base, entrypoint, **kwargs)


# Workaround for https://github.com/bazelbuild/bazel/issues/5633
def rename_debs(debs):
    outs = []
    for i, downloaded_deb in enumerate(debs):
        name = "deb_{}".format(i)
        out = "{}.deb".format(name)
        outs.append(out)
        native.genrule(
            name=name,
            outs=["{}.deb".format(name)],
            srcs=[downloaded_deb],
            cmd="cp $< $@",
        )
    return outs
