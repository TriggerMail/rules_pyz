# AUTO GENERATED. DO NOT EDIT DIRECTLY.
#
# Command line:
#   pypi/pip_generate \
#     --wheelToolPath=/Users/evanjones/rules_pyz/bazel-bin/pypi/pip_generate_wrapper.runfiles/com_bluecore_rules_pyz/pypi/wheeltool -requirements=requirements.txt -outputDir=third_party/pypi -outputBzlFileName=new.bzl -wheelDir=whl --wheelURLPrefix=https://storage.googleapis.com/bluecore-bazel/

load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "pyz_library")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

_BUILD_FILE_CONTENT='''
load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "pyz_library")

pyz_library(
    name="lib",
    srcs=glob(["**/*.py"]),
    data = glob(["**/*"], exclude=["**/*.py", "BUILD", "WORKSPACE", "*.whl.zip"]),
    pythonroot=".",
    visibility=["//visibility:public"],
)
'''

def pypi_libraries():
    pyz_library(
        name="asn1crypto",
        deps=[
        ] + ["@pypi_asn1crypto//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="bcrypt",
        deps=[
            "cffi",
            "six",
        ] + select({
            "@com_bluecore_rules_pyz//rules_python_zip:linux": ["@pypi_bcrypt__linux//:lib"],
            "@com_bluecore_rules_pyz//rules_python_zip:osx": ["@pypi_bcrypt__osx//:lib"],
        }),
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="cachetools",
        deps=[
        ] + ["@pypi_cachetools//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="certifi",
        zip_safe=False,
        deps=[
        ] + ["@pypi_certifi//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="cffi",
        deps=[
            "pycparser",
        ] + select({
            "@com_bluecore_rules_pyz//rules_python_zip:linux": ["@pypi_cffi__linux//:lib"],
            "@com_bluecore_rules_pyz//rules_python_zip:osx": ["@pypi_cffi__osx//:lib"],
        }),
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="chardet",
        deps=[
        ] + ["@pypi_chardet//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="cryptography",
        deps=[
            "asn1crypto",
            "cffi",
            "enum34",
            "idna",
            "ipaddress",
            "six",
        ] + select({
            "@com_bluecore_rules_pyz//rules_python_zip:linux": ["@pypi_cryptography__linux//:lib"],
            "@com_bluecore_rules_pyz//rules_python_zip:osx": ["@pypi_cryptography__osx//:lib"],
        }),
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="enum34",
        deps=[
        ] + ["@pypi_enum34//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="futures",
        deps=[
        ] + ["@pypi_futures//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="google_api_core",
        deps=[
            "futures",
            "google_auth",
            "googleapis_common_protos",
            "protobuf",
            "pytz",
            "requests",
            "setuptools",
            "six",
        ] + ["@pypi_google_api_core//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="google_api_core__grpc",
        deps=[
            ":google_api_core",
            "grpcio",
        ],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="google_auth",
        deps=[
            "cachetools",
            "pyasn1_modules",
            "rsa",
            "six",
        ] + ["@pypi_google_auth//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="google_cloud_core",
        deps=[
            "google_api_core",
        ] + ["@pypi_google_cloud_core//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="google_cloud_core__grpc",
        deps=[
            ":google_cloud_core",
            "grpcio",
        ],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="google_cloud_datastore",
        deps=[
            "google_api_core__grpc",
            "google_cloud_core",
        ] + ["@pypi_google_cloud_datastore//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="googleapis_common_protos",
        deps=[
            "protobuf",
        ] + ["@pypi_googleapis_common_protos//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="googleapis_common_protos__grpc",
        deps=[
            ":googleapis_common_protos",
            "grpcio",
        ],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="grpcio",
        deps=[
            "enum34",
            "futures",
            "six",
        ] + select({
            "@com_bluecore_rules_pyz//rules_python_zip:linux": ["@pypi_grpcio__linux//:lib"],
            "@com_bluecore_rules_pyz//rules_python_zip:osx": ["@pypi_grpcio__osx//:lib"],
        }),
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="idna",
        deps=[
        ] + ["@pypi_idna//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="ipaddress",
        deps=[
        ] + ["@pypi_ipaddress//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="numpy",
        deps=[
        ] + select({
            "@com_bluecore_rules_pyz//rules_python_zip:linux": ["@pypi_numpy__linux//:lib"],
            "@com_bluecore_rules_pyz//rules_python_zip:osx": ["@pypi_numpy__osx//:lib"],
        }),
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="protobuf",
        deps=[
            "setuptools",
            "six",
        ] + select({
            "@com_bluecore_rules_pyz//rules_python_zip:linux": ["@pypi_protobuf__linux//:lib"],
            "@com_bluecore_rules_pyz//rules_python_zip:osx": ["@pypi_protobuf__osx//:lib"],
        }),
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="pyasn1",
        deps=[
        ] + ["@pypi_pyasn1//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="pyasn1_modules",
        deps=[
            "pyasn1",
        ] + ["@pypi_pyasn1_modules//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="pycparser",
        deps=[
        ] + ["@pypi_pycparser//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="pytz",
        deps=[
        ] + ["@pypi_pytz//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="requests",
        deps=[
            "certifi",
            "chardet",
            "idna",
            "urllib3",
        ] + ["@pypi_requests//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="rsa",
        deps=[
            "pyasn1",
        ] + ["@pypi_rsa//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="scipy",
        deps=[
            "numpy",
        ] + select({
            "@com_bluecore_rules_pyz//rules_python_zip:linux": ["@pypi_scipy__linux//:lib"],
            "@com_bluecore_rules_pyz//rules_python_zip:osx": ["@pypi_scipy__osx//:lib"],
        }),
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="setuptools",
        deps=[
        ] + ["@pypi_setuptools//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="setuptools__certs",
        deps=[
            ":setuptools",
            "certifi",
        ],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="setuptools__ssl",
        deps=[
            ":setuptools",
        ],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="six",
        deps=[
        ] + ["@pypi_six//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="urllib3",
        deps=[
        ] + ["@pypi_urllib3//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )
    pyz_library(
        name="virtualenv",
        deps=[
        ] + ["@pypi_virtualenv//:lib"],
        licenses=["notice"],
        visibility=["//visibility:public"],
    )

def pypi_repositories():
    existing_rules = native.existing_rules()
    if "pypi_asn1crypto" not in existing_rules:
        http_archive(
            name="pypi_asn1crypto",
            url="https://files.pythonhosted.org/packages/ea/cd/35485615f45f30a510576f1a56d1e0a7ad7bd8ab5ed7cdc600ef7cd06222/asn1crypto-0.24.0-py2.py3-none-any.whl",
            sha256="2f1adbb7546ed199e3c90ef23ec95c5cf3585bac7d11fb7eb562a3fe89c64e87",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_bcrypt__linux" not in existing_rules:
        http_archive(
            name="pypi_bcrypt__linux",
            url="https://files.pythonhosted.org/packages/2e/5a/2abeae20ce294fe6bf63da0e0b5a885c788e1360bbd124edcc0429678a59/bcrypt-3.1.4-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="2788c32673a2ad0062bea850ab73cffc0dba874db10d7a3682b6f2f280553f20",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_bcrypt__osx" not in existing_rules:
        http_archive(
            name="pypi_bcrypt__osx",
            url="https://files.pythonhosted.org/packages/a1/9c/c89411a505dca5ae822a28c6de6946583ff8a1d5d9190292f301d28dcf85/bcrypt-3.1.4-cp27-cp27m-macosx_10_6_intel.whl",
            sha256="0f317e4ffbdd15c3c0f8ab5fbd86aa9aabc7bea18b5cc5951b456fe39e9f738c",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_cachetools" not in existing_rules:
        http_archive(
            name="pypi_cachetools",
            url="https://files.pythonhosted.org/packages/0a/58/cbee863250b31d80f47401d04f34038db6766f95dea1cc909ea099c7e571/cachetools-2.1.0-py2.py3-none-any.whl",
            sha256="d1c398969c478d336f767ba02040fa22617333293fb0b8968e79b16028dfee35",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_certifi" not in existing_rules:
        http_archive(
            name="pypi_certifi",
            url="https://files.pythonhosted.org/packages/7c/e6/92ad559b7192d846975fc916b65f667c7b8c3a32bea7372340bfe9a15fa5/certifi-2018.4.16-py2.py3-none-any.whl",
            sha256="9fa520c1bacfb634fa7af20a76bcbd3d5fb390481724c597da32c719a7dca4b0",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_cffi__linux" not in existing_rules:
        http_archive(
            name="pypi_cffi__linux",
            url="https://files.pythonhosted.org/packages/14/dd/3e7a1e1280e7d767bd3fa15791759c91ec19058ebe31217fe66f3e9a8c49/cffi-1.11.5-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="edabd457cd23a02965166026fd9bfd196f4324fe6032e866d0f3bd0301cd486f",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_cffi__osx" not in existing_rules:
        http_archive(
            name="pypi_cffi__osx",
            url="https://files.pythonhosted.org/packages/7e/4a/b647e46faaa2dcfb16069b6aad2d8509982fd63710a325b8ad7db80f18be/cffi-1.11.5-cp27-cp27m-macosx_10_6_intel.whl",
            sha256="1b0493c091a1898f1136e3f4f991a784437fac3673780ff9de3bcf46c80b6b50",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_chardet" not in existing_rules:
        http_archive(
            name="pypi_chardet",
            url="https://files.pythonhosted.org/packages/bc/a9/01ffebfb562e4274b6487b4bb1ddec7ca55ec7510b22e4c51f14098443b8/chardet-3.0.4-py2.py3-none-any.whl",
            sha256="fc323ffcaeaed0e0a02bf4d117757b98aed530d9ed4531e3e15460124c106691",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_cryptography__linux" not in existing_rules:
        http_archive(
            name="pypi_cryptography__linux",
            url="https://files.pythonhosted.org/packages/dd/c2/3a5bfefb25690725824ade71e6b65449f0a9f4b29702cce10560f786ebf6/cryptography-2.2.2-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="6fef51ec447fe9f8351894024e94736862900d3a9aa2961528e602eb65c92bdb",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_cryptography__osx" not in existing_rules:
        http_archive(
            name="pypi_cryptography__osx",
            url="https://files.pythonhosted.org/packages/58/c1/23bea66007d4be75ce02056fac665f9a207535e89fb3c7931420fa4a5f57/cryptography-2.2.2-cp27-cp27m-macosx_10_6_intel.whl",
            sha256="abd070b5849ed64e6d349199bef955ee0ad99aefbad792f0c587f8effa681a5e",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_enum34" not in existing_rules:
        http_archive(
            name="pypi_enum34",
            url="https://files.pythonhosted.org/packages/c5/db/e56e6b4bbac7c4a06de1c50de6fe1ef3810018ae11732a50f15f62c7d050/enum34-1.1.6-py2-none-any.whl",
            sha256="6bd0f6ad48ec2aa117d3d141940d484deccda84d4fcd884f5c3d93c23ecd8c79",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_futures" not in existing_rules:
        http_archive(
            name="pypi_futures",
            url="https://files.pythonhosted.org/packages/2d/99/b2c4e9d5a30f6471e410a146232b4118e697fa3ffc06d6a65efde84debd0/futures-3.2.0-py2-none-any.whl",
            sha256="ec0a6cb848cc212002b9828c3e34c675e0c9ff6741dc445cab6fdd4e1085d1f1",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_google_api_core" not in existing_rules:
        http_archive(
            name="pypi_google_api_core",
            url="https://files.pythonhosted.org/packages/2f/19/4f45c195de8b02d24a21891100d012afcb80b91c198971fc1b95be067052/google_api_core-1.2.0-py2.py3-none-any.whl",
            sha256="c11cdbb6781a2c26b4b3d7e7c07a4d3c166d7d4d2173fc5ca520798d2d19de62",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_google_auth" not in existing_rules:
        http_archive(
            name="pypi_google_auth",
            url="https://files.pythonhosted.org/packages/53/06/6e6d5bfa4d23ee40efd772d6b681a7afecd859a9176e564b8c329382370f/google_auth-1.5.0-py2.py3-none-any.whl",
            sha256="82a34e1a59ad35f01484d283d2a36b7a24c8c404a03a71b3afddd0a4d31e169f",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_google_cloud_core" not in existing_rules:
        http_archive(
            name="pypi_google_cloud_core",
            url="https://files.pythonhosted.org/packages/0f/41/ae2418b4003a14cf21c1c46d61d1b044bf02cf0f8f91598af572b9216515/google_cloud_core-0.28.1-py2.py3-none-any.whl",
            sha256="0090df83dbc5cb2405fa90844366d13176d1c0b48181c1807ab15f53be403f73",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_google_cloud_datastore" not in existing_rules:
        http_archive(
            name="pypi_google_cloud_datastore",
            url="https://files.pythonhosted.org/packages/9d/1b/2d47219d50f818706a1202558d4365cf2fcf4c092c18db68065164944667/google_cloud_datastore-1.6.0-py2.py3-none-any.whl",
            sha256="3f43409a15451b69161eb321826dd2e014191822ef7af7e71423cec85d921b01",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_googleapis_common_protos" not in existing_rules:
        http_archive(
            name="pypi_googleapis_common_protos",
            url="https://storage.googleapis.com/bluecore-bazel/googleapis_common_protos-1.5.3-py2-none-any.whl",
            sha256="688b20bc1a70a6ae3178ee296adb8bb0d04f64e2734c528b302c7024bf2abb7d",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_grpcio__linux" not in existing_rules:
        http_archive(
            name="pypi_grpcio__linux",
            url="https://files.pythonhosted.org/packages/2a/d5/eb371e43d65989267a9daa90ee8f92d79b216184ea3c8cf0670e5c2388eb/grpcio-1.12.0-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="fd5409f797a01d82e80800d078b6ee43ddae43cf93ad2b30d601e471f08bec96",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_grpcio__osx" not in existing_rules:
        http_archive(
            name="pypi_grpcio__osx",
            url="https://files.pythonhosted.org/packages/0a/9d/aa4dd93ae061526e5ba6b8e9f6e11095ed9df70fdf0a3ad9288a600a76c1/grpcio-1.12.0-cp27-cp27m-macosx_10_12_x86_64.whl",
            sha256="e87393c34532636741e06f39d01ef1df0c7ca751b4aa15d6ac8fb6482484de9f",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_idna" not in existing_rules:
        http_archive(
            name="pypi_idna",
            url="https://files.pythonhosted.org/packages/27/cc/6dd9a3869f15c2edfab863b992838277279ce92663d334df9ecf5106f5c6/idna-2.6-py2.py3-none-any.whl",
            sha256="8c7309c718f94b3a625cb648ace320157ad16ff131ae0af362c9f21b80ef6ec4",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_ipaddress" not in existing_rules:
        http_archive(
            name="pypi_ipaddress",
            url="https://files.pythonhosted.org/packages/fc/d0/7fc3a811e011d4b388be48a0e381db8d990042df54aa4ef4599a31d39853/ipaddress-1.0.22-py2.py3-none-any.whl",
            sha256="64b28eec5e78e7510698f6d4da08800a5c575caa4a286c93d651c5d3ff7b6794",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_numpy__linux" not in existing_rules:
        http_archive(
            name="pypi_numpy__linux",
            url="https://files.pythonhosted.org/packages/c0/e7/08f059a00367fd613e4f2875a16c70b6237268a1d6d166c6d36acada8301/numpy-1.14.3-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="0db6301324d0568089663ef2701ad90ebac0e975742c97460e89366692bd0563",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_numpy__osx" not in existing_rules:
        http_archive(
            name="pypi_numpy__osx",
            url="https://files.pythonhosted.org/packages/b8/97/ecff917542e3a8a33bc8e88c031ed50c90577fd205eab362b29f3e57c09e/numpy-1.14.3-cp27-cp27m-macosx_10_6_intel.macosx_10_9_intel.macosx_10_9_x86_64.macosx_10_10_intel.macosx_10_10_x86_64.whl",
            sha256="a8dbab311d4259de5eeaa5b4e83f5f8545e4808f9144e84c0f424a6ee55a7b98",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_protobuf__linux" not in existing_rules:
        http_archive(
            name="pypi_protobuf__linux",
            url="https://files.pythonhosted.org/packages/9d/61/54c3a9cfde6ffe0ca6a1786ddb8874263f4ca32e7693ad383bd8cf935015/protobuf-3.5.2.post1-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="5c1c8f6a0a68a874e3beff89255959dd80fad45870e96c88944a1b81a22dd5f5",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_protobuf__osx" not in existing_rules:
        http_archive(
            name="pypi_protobuf__osx",
            url="https://files.pythonhosted.org/packages/c7/15/e21b9597043ecdc586b76b29608b30212658d239d66407621a642aedb41f/protobuf-3.5.2.post1-cp27-cp27m-macosx_10_6_intel.macosx_10_9_intel.macosx_10_9_x86_64.macosx_10_10_intel.macosx_10_10_x86_64.whl",
            sha256="ac0067e3c60737865ed72bb7416e02297d229d960902802d874c0e167128c809",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_pyasn1" not in existing_rules:
        http_archive(
            name="pypi_pyasn1",
            url="https://files.pythonhosted.org/packages/a0/70/2c27740f08e477499ce19eefe05dbcae6f19fdc49e9e82ce4768be0643b9/pyasn1-0.4.3-py2.py3-none-any.whl",
            sha256="a66dcda18dbf6e4663bde70eb30af3fc4fe1acb2d14c4867a861681887a5f9a2",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_pyasn1_modules" not in existing_rules:
        http_archive(
            name="pypi_pyasn1_modules",
            url="https://files.pythonhosted.org/packages/e9/51/bcd96bf6231d4b2cc5e023c511bee86637ba375c44a6f9d1b4b7ad1ce4b9/pyasn1_modules-0.2.1-py2.py3-none-any.whl",
            sha256="47fb6757ab78fe966e7c58b2030b546854f78416d653163f0ce9290cf2278e8b",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_pycparser" not in existing_rules:
        http_archive(
            name="pypi_pycparser",
            url="https://storage.googleapis.com/bluecore-bazel/pycparser-2.18-py2.py3-none-any.whl",
            sha256="93497f9af35e9545b7eb5e20e77e2ff566499b83890a0c620af4527e2e28cc95",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_pytz" not in existing_rules:
        http_archive(
            name="pypi_pytz",
            url="https://files.pythonhosted.org/packages/dc/83/15f7833b70d3e067ca91467ca245bae0f6fe56ddc7451aa0dc5606b120f2/pytz-2018.4-py2.py3-none-any.whl",
            sha256="65ae0c8101309c45772196b21b74c46b2e5d11b6275c45d251b150d5da334555",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_requests" not in existing_rules:
        http_archive(
            name="pypi_requests",
            url="https://files.pythonhosted.org/packages/49/df/50aa1999ab9bde74656c2919d9c0c085fd2b3775fd3eca826012bef76d8c/requests-2.18.4-py2.py3-none-any.whl",
            sha256="6a1b267aa90cac58ac3a765d067950e7dbbf75b1da07e895d1f594193a40a38b",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_rsa" not in existing_rules:
        http_archive(
            name="pypi_rsa",
            url="https://files.pythonhosted.org/packages/e1/ae/baedc9cb175552e95f3395c43055a6a5e125ae4d48a1d7a924baca83e92e/rsa-3.4.2-py2.py3-none-any.whl",
            sha256="43f682fea81c452c98d09fc316aae12de6d30c4b5c84226642cf8f8fd1c93abd",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_scipy__linux" not in existing_rules:
        http_archive(
            name="pypi_scipy__linux",
            url="https://files.pythonhosted.org/packages/2a/f3/de9c1bd16311982711209edaa8c6caa962db30ebb6a8cc6f1dcd2d3ef616/scipy-1.1.0-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="08237eda23fd8e4e54838258b124f1cd141379a5f281b0a234ca99b38918c07a",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_scipy__osx" not in existing_rules:
        http_archive(
            name="pypi_scipy__osx",
            url="https://files.pythonhosted.org/packages/d1/d6/3eac96ffcf7cbeb37ed72982cf3fdd3138472cb04ab32cdce1f444d765f2/scipy-1.1.0-cp27-cp27m-macosx_10_6_intel.macosx_10_9_intel.macosx_10_9_x86_64.macosx_10_10_intel.macosx_10_10_x86_64.whl",
            sha256="340ef70f5b0f4e2b4b43c8c8061165911bc6b2ad16f8de85d9774545e2c47463",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_setuptools" not in existing_rules:
        http_archive(
            name="pypi_setuptools",
            url="https://files.pythonhosted.org/packages/7f/e1/820d941153923aac1d49d7fc37e17b6e73bfbd2904959fffbad77900cf92/setuptools-39.2.0-py2.py3-none-any.whl",
            sha256="8fca9275c89964f13da985c3656cb00ba029d7f3916b37990927ffdf264e7926",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_six" not in existing_rules:
        http_archive(
            name="pypi_six",
            url="https://files.pythonhosted.org/packages/67/4b/141a581104b1f6397bfa78ac9d43d8ad29a7ca43ea90a2d863fe3056e86a/six-1.11.0-py2.py3-none-any.whl",
            sha256="832dc0e10feb1aa2c68dcc57dbb658f1c7e65b9b61af69048abc87a2db00a0eb",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_urllib3" not in existing_rules:
        http_archive(
            name="pypi_urllib3",
            url="https://files.pythonhosted.org/packages/63/cb/6965947c13a94236f6d4b8223e21beb4d576dc72e8130bd7880f600839b8/urllib3-1.22-py2.py3-none-any.whl",
            sha256="06330f386d6e4b195fbfc736b297f58c5a892e4440e54d294d7004e3a9bbea1b",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_virtualenv" not in existing_rules:
        http_archive(
            name="pypi_virtualenv",
            url="https://files.pythonhosted.org/packages/b6/30/96a02b2287098b23b875bc8c2f58071c35d2efe84f747b64d523721dc2b5/virtualenv-16.0.0-py2.py3-none-any.whl",
            sha256="2ce32cd126117ce2c539f0134eb89de91a8413a29baac49cbab3eb50e2026669",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
