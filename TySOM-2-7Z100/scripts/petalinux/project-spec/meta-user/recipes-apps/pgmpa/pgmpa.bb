#
# This file is the pgmpa recipe.
#
FILESEXTRAPATHS:append := ":${THISDIR}/files"
SUMMARY = "Simple pgmpa application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://driver \
           file://Makefile \
           file://pgmpa.c \
           file://axis-fifo.h \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}/home/petalinux/pgmpa/powernn/powernn_100
    install -m 0744 ${WORKDIR}/driver/powernn/powernn_100/busA.sim ${D}/home/petalinux/pgmpa/powernn/powernn_100/busA.sim
    install -m 0744 ${WORKDIR}/driver/powernn/powernn_100/busB.sim ${D}/home/petalinux/pgmpa/powernn/powernn_100/busB.sim
    install -m 0744 ${WORKDIR}/driver/powernn/powernn_100/prog.sim ${D}/home/petalinux/pgmpa/powernn/powernn_100/prog.sim
    install -m 0755 pgmpa.c     ${D}/home/petalinux/pgmpa/
    install -m 0755 axis-fifo.h ${D}/home/petalinux/pgmpa/
    install -m 0755 pgmpa       ${D}/home/petalinux/pgmpa/
}

DEBUG_FLAGS = "-Wall -g3 -O0"

# Specifies to build packages with debugging information
DEBUG_BUILD = "1"

# Do not remove debug symbols
INHIBIT_PACKAGE_STRIP = "1"

# OPTIONAL: Do not split debug symbols in a separate file
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

do_compile() {
    oe_runmake
}

FILES:${PN} += "/home/petalinux"
