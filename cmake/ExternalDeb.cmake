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

    set (GLIBMM_PREFIX "${CMAKE_BINARY_DIR}/${NAME}-prefix")

    include (ExternalProject)
    ExternalProject_Add (${NAME}
        DOWNLOAD_COMMAND cd ${NAME} && ${PATH_WGET} -O ${NAME}.deb ${URL} && ar x ${NAME}.deb && tar -xf data.tar.xz

        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
    )

    set (${NAME}_FOUND TRUE PARENT_SCOPE)

    file (GLOB INCLUDE_DIRS "${GLIBMM_PREFIX}/src/${NAME}/usr/include/*")
    set (${NAME}_INCLUDE_DIRS "${INCLUDE_DIRS}" PARENT_SCOPE)

    file (GLOB LIBRARY_DIRS "${GLIBMM_PREFIX}/src/${NAME}/usr/lib/*")
    set (${NAME}_LIBRARY_DIRS "${LIBRARY_DIRS}" PARENT_SCOPE)
    link_directories (${LIBRARY_DIRS})

    foreach (DIRECTORY ${LIBRARY_DIRS})
        file (GLOB SLIBRARIES_TMP "${DIRECTORY}/*.a")
        set (${NAME}_SLIBRARIES ${${NAME}_SLIBRARIES} ${SLIBRARIES_TMP} PARENT_SCOPE)

        file (GLOB DLIBRARIES_TMP "${DIRECTORY}/*.so")
        set (${NAME}_DLIBRARIES ${${NAME}_DLIBRARIES} ${DLIBRARIES_TMP} PARENT_SCOPE)
    endforeach (DIRECTORY)

endfunction (ExternalDeb_add)