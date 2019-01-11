The second layer contains the following filesystem structure:
* `/merged/: m1`
* `/replaced1/: r1`
* `/replaced2/: r2`
* `/replaced3`
* `/replaced4@ -> /merged`
* `/foo@ -> baz`
* `/bar@ -> bar` (dangling link)
* `/baz`
* `/xyz@ -> ../../../../../../../abc`
The symbolic link `/xyz` should link to `/abc` after chroot, and thus a dangling link. However, during image provisioning, it would link to the `abc` file under the agent's work directory on the host filesystem, according to the [provisioner filesystem layout](https://github.com/apache/mesos/blob/594ea4c79f28832e4b40fb0804dca24a7ba11c07/src/slave/containerizer/mesos/provisioner/paths.hpp#L34). In test [`ProvisionerDockerBackendTest.ROOT_INTERNET_CURL_DTYPE_Overwrite`](https://github.com/apache/mesos/blob/594ea4c79f28832e4b40fb0804dca24a7ba11c07/src/tests/containerizer/provisioner_docker_tests.cpp#L933), a non-empty file `abc` is created under the agent's work directory, which should not be overwritten during provisioning.

The third layer will overwrite directories `/replaced1/` and `/replaced2/` with regular file `/replaced1` and symbolic link `/replaced2@ -> /merged`, and overwrite files `/replaced3` and `/replaced4` with directories of the same names. Also, link `/bar` is replaced by a file and file `/baz` is replaced by a link. No whiteout files will be generated. The final filesystem structure will be:
* `/merged/: m1 m2`
* `/replaced1`
* `/replaced2@ -> /merged`
* `/replaced3/: (empty)`
* `/replaced4/: (empty)`
* `/foo@ -> bar`
* `/bar`
* `/baz@ -> baz` (dangling link)
* `/xyz`

Test [`ProvisionerDockerBackendTest.ROOT_INTERNET_CURL_DTYPE_Overwrite`](https://github.com/apache/mesos/blob/594ea4c79f28832e4b40fb0804dca24a7ba11c07/src/tests/containerizer/provisioner_docker_tests.cpp#L933) verifies the following statements after provisioning:
* `/replaced1` is a regular file.
* `/replaced2` is a symbolic link.
* `/replaced2/` contains both `m1` and `m2` but not `r2`.
* `/replaced3` and `/replaced4` are directories.
* `/replaced4/` does not contain `m1`
* `/foo` links to a regular file, meaning that the old link is replaced with the new link.
* `/bar` is a not a symbolic link.
* `/baz` is a symbolic lick.
* `abc` on the host filesystem is not overwritten by `xyz` and remains non-empty.
