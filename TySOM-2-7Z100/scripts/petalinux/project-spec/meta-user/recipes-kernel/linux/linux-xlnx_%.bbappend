FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = "  file://0001-axis-fifo.patch \
                    file://axis_fifo.cfg \
                    file://bsp.cfg \
"
KERNEL_FEATURES:append = " bsp.cfg axis_fifo.cfg"
