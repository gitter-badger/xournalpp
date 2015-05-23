function (target_architecture_deb output_var)
    include (TargetArch)
    target_architecture(ARCH)

    if (${ARCH} STREQUAL armv7)
        set (DARCH armhf)
    elseif (${ARCH} STREQUAL armv6)
        set (DARCH armel)
    elseif (${ARCH} STREQUAL armv5)
        set (DARCH armel)
    elseif (${ARCH} STREQUAL arm)
        set (DARCH arm)
    elseif (${ARCH} STREQUAL i386)
        set (DARCH i386)
    elseif (${ARCH} STREQUAL x86_64)
        set (DARCH amd64)
    elseif (${ARCH} STREQUAL ia64)
        set (DARCH ia64)
    elseif (${ARCH} STREQUAL ppc64)
        set (DARCH ppc64)
    elseif (${ARCH} STREQUAL ppc)
        set (DARCH powerpc)
    elseif (${ARCH} STREQUAL unknown)
        set (DARCH unknown)
    endif (${ARCH} STREQUAL armv7)

    set (${output_var} ${DARCH} PARENT_SCOPE)
endfunction (target_architecture_deb)

function (ExternalDeb_add NAME URL)

    find_program (PATH_WGET wget)
    if (NOT PATH_WGET)
        message (FATAL_ERROR "Wget not found (needed to download deb files)")
    endif (NOT PATH_WGET)

    find_program (PATH_AR ar)
    if (NOT PATH_AR)
        message (FATAL_ERROR "Ar not found (needed to unpack deb files)")
    endif (NOT PATH_AR)

    target_architecture_deb (ARCH)
    set (URL "${URL}")
    string (REPLACE "%ARCH%" ${ARCH} URL "${URL}")

    include (ExternalProject)
    ExternalProject_Add (${NAME}
        DOWNLOAD_COMMAND cd glibmm && ${PATH_WGET} -O ${NAME}.deb ${URL} && ar x ${NAME}.deb && tar -xf data.tar.xz

        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
    )

endfunction (ExternalDeb_add)