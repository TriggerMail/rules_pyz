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
            url="https://files.pythonhosted.org/packages/df/f7/04fee6ac349e915b82171f8e23cee63644d83663b34c539f7a09aed18f9e/certifi-2018.8.24-py2.py3-none-any.whl",
            sha256="456048c7e371c089d0a77a5212fb37a2c2dce1e24146e3b7e0261736aaeaa22a",
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
            url="https://files.pythonhosted.org/packages/87/e6/915a482dbfef98bbdce6be1e31825f591fc67038d4ee09864c1d2c3db371/cryptography-2.3.1-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="31db8febfc768e4b4bd826750a70c79c99ea423f4697d1dab764eb9f9f849519",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_cryptography__osx" not in existing_rules:
        http_archive(
            name="pypi_cryptography__osx",
            url="https://files.pythonhosted.org/packages/5d/b1/9863611b121ee524135bc0068533e6d238cc837337170e722224fe940e2d/cryptography-2.3.1-cp27-cp27m-macosx_10_6_intel.whl",
            sha256="17db09db9d7c5de130023657be42689d1a5f60502a14f6f745f6f65a6b8195c0",
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
            url="https://files.pythonhosted.org/packages/29/de/2b86f01a00eb72a5cbb80a720cd247e67eba8972cbb0914f45623693476d/google_api_core-1.4.0-py2.py3-none-any.whl",
            sha256="1953a4109ede689cf681c43d91cc1fd55e2432b52b6337f95f5a1841bcb3b707",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_google_auth" not in existing_rules:
        http_archive(
            name="pypi_google_auth",
            url="https://files.pythonhosted.org/packages/58/cb/96dbb4e50e7a9d856e89cc9c8e36ab1055f9774f7d85f37e2156c1d79d9f/google_auth-1.5.1-py2.py3-none-any.whl",
            sha256="a4cf9e803f2176b5de442763bd339b313d3f1ed3002e3e1eb6eec1d7c9bbc9b4",
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
            url="https://files.pythonhosted.org/packages/d8/4b/aab0f1578eff1146e019670e079f5f939e46c5b004b65063b450c8d87af0/google_cloud_datastore-1.7.0-py2.py3-none-any.whl",
            sha256="ff15ce4a2ff82a7655e1bfe5a72159c6518598b4cd65c7003c19d472c6ff8b71",
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
            url="https://files.pythonhosted.org/packages/3d/15/b34114198a2bc9c9bb73b21e2b559468a1a68bb28b373d21da6e51d6204f/grpcio-1.15.0-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="670e884e5b5c8805e30d214da790cb86487db27ed9e7ccd74f11a2bc5a27df2b",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_grpcio__osx" not in existing_rules:
        http_archive(
            name="pypi_grpcio__osx",
            url="https://files.pythonhosted.org/packages/13/b5/7ada39c840c53f7cd2db642a2cd66d768a1366b4c26ffba4ec9e46bea58e/grpcio-1.15.0-cp27-cp27m-macosx_10_12_x86_64.whl",
            sha256="16cdd82a3aed9b6d3067492413bfffe61bf0f98c06f2942f887d79b8fd68898d",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_idna" not in existing_rules:
        http_archive(
            name="pypi_idna",
            url="https://files.pythonhosted.org/packages/4b/2a/0276479a4b3caeb8a8c1af2f8e4355746a97fab05a372e4a2c6a6b876165/idna-2.7-py2.py3-none-any.whl",
            sha256="156a6814fb5ac1fc6850fb002e0852d56c0c8d2531923a51032d1b70760e186e",
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
            url="https://files.pythonhosted.org/packages/c9/16/1134977cc35d2f72dbe80efa75a8e989ac21289f8e7e2c9005444cd17cd5/numpy-1.15.1-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="df0b02c6705c5d1c25cc35c7b5d6b6f9b3b30833f9d178843397ae55ecc2eebb",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_numpy__osx" not in existing_rules:
        http_archive(
            name="pypi_numpy__osx",
            url="https://files.pythonhosted.org/packages/e7/c1/d5c47de35e366b1c2f60da88a24b25d3037b892417c5c3c5398313fb54f5/numpy-1.15.1-cp27-cp27m-macosx_10_6_intel.macosx_10_9_intel.macosx_10_9_x86_64.macosx_10_10_intel.macosx_10_10_x86_64.whl",
            sha256="5e359e9c531075220785603e5966eef20ccae9b3b6b8a06fdfb66c084361ce92",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_protobuf__linux" not in existing_rules:
        http_archive(
            name="pypi_protobuf__linux",
            url="https://files.pythonhosted.org/packages/b8/c2/b7f587c0aaf8bf2201405e8162323037fe8d17aa21d3c7dda811b8d01469/protobuf-3.6.1-cp27-cp27mu-manylinux1_x86_64.whl",
            sha256="59cd75ded98094d3cf2d79e84cdb38a46e33e7441b2826f3838dcc7c07f82995",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_protobuf__osx" not in existing_rules:
        http_archive(
            name="pypi_protobuf__osx",
            url="https://files.pythonhosted.org/packages/2b/2b/d51219eb18a140836cb656053e5408cd18fd752217ff73ca596204cd3183/protobuf-3.6.1-cp27-cp27m-macosx_10_6_intel.macosx_10_9_intel.macosx_10_9_x86_64.macosx_10_10_intel.macosx_10_10_x86_64.whl",
            sha256="10394a4d03af7060fa8a6e1cbf38cea44be1467053b0aea5bbfcb4b13c4b88c4",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_pyasn1" not in existing_rules:
        http_archive(
            name="pypi_pyasn1",
            url="https://files.pythonhosted.org/packages/d1/a1/7790cc85db38daa874f6a2e6308131b9953feb1367f2ae2d1123bb93a9f5/pyasn1-0.4.4-py2.py3-none-any.whl",
            sha256="b9d3abc5031e61927c82d4d96c1cec1e55676c1a991623cfed28faea73cdd7ca",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_pyasn1_modules" not in existing_rules:
        http_archive(
            name="pypi_pyasn1_modules",
            url="https://files.pythonhosted.org/packages/19/02/fa63f7ba30a0d7b925ca29d034510fc1ffde53264b71b4155022ddf3ab5d/pyasn1_modules-0.2.2-py2.py3-none-any.whl",
            sha256="a38a8811ea784c0136abfdba73963876328f66172db21a05a82f9515909bfb4e",
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
            url="https://files.pythonhosted.org/packages/30/4e/27c34b62430286c6d59177a0842ed90dc789ce5d1ed740887653b898779a/pytz-2018.5-py2.py3-none-any.whl",
            sha256="a061aa0a9e06881eb8b3b2b43f05b9439d6583c206d0a6c340ff72a7b6669053",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_requests" not in existing_rules:
        http_archive(
            name="pypi_requests",
            url="https://files.pythonhosted.org/packages/65/47/7e02164a2a3db50ed6d8a6ab1d6d60b69c4c3fdf57a284257925dfc12bda/requests-2.19.1-py2.py3-none-any.whl",
            sha256="63b52e3c866428a224f97cab011de738c36aec0185aa91cfacd418b5d58911d1",
            build_file_content=_BUILD_FILE_CONTENT,
            type="zip",
        )
    if "pypi_rsa" not in existing_rules:
        http_archive(
            name="pypi_rsa",
            url="https://files.pythonhosted.org/packages/02/e5/38518af393f7c214357079ce67a317307936896e961e35450b70fad2a9cf/rsa-4.0-py2.py3-none-any.whl",
            sha256="14ba45700ff1ec9eeb206a2ce76b32814958a98e372006c8fb76ba820211be66",
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
            url="https://files.pythonhosted.org/packages/81/17/a6301c14aa0c0dd02938198ce911eba84602c7e927a985bf9015103655d1/setuptools-40.4.1-py2.py3-none-any.whl",
            sha256="822054653e22ef38eef400895b8ada55657c8db7ad88f7ec954bccff2b3b9b52",
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
            url="https://files.pythonhosted.org/packages/bd/c9/6fdd990019071a4a32a5e7cb78a1d92c53851ef4f56f62a3486e6a7d8ffb/urllib3-1.23-py2.py3-none-any.whl",
            sha256="b5725a0bd4ba422ab0e66e89e030c806576753ea3ee08554382c14e685d117b5",
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
