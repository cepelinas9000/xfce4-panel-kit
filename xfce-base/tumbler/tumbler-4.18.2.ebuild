# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Thumbnail service implementing the thumbnail management D-Bus specification"
HOMEPAGE="https://gitlab.xfce.org/xfce/tumbler"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/10/repository/archive.tar.bz2?sha=tumbler-4.18.2 -> tumbler-4.18.2.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"
IUSE="curl epub ffmpeg gstreamer jpeg odf pdf raw"

RDEPEND="gstreamer? ( media-plugins/gst-plugins-meta:1.0 )
	"

DEPEND="${RDEPEND}
	>=xfce-base/libxfce4util-4.17.1
	curl? ( >=net-misc/curl-7.32.0:= )
	epub? ( app-text/libgepub )
	ffmpeg? ( >=media-video/ffmpegthumbnailer-2.0.8:= )
	gstreamer? (
		media-libs/gstreamer:1.0
		media-libs/gst-plugins-base:1.0
	)
	jpeg? ( media-libs/libjpeg-turbo:0= )
	odf? ( >=gnome-extra/libgsf-1.14.20:= )
	pdf? ( >=app-text/poppler-0.12.4[cairo] )
	raw? ( >=media-libs/libopenraw-0.0.8:=[gtk] )
"

BDEPEND="
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig
	dev-util/gtk-doc-am"

post_src_unpack() {
	if [ ! -d "${S}" ] ; then
		mv "${WORKDIR}"/${PN}-* "${S}" || die
	fi
}

src_prepare() {
	NOCONFIGURE=1 ./autogen.sh
	default
	eautoreconf
}

src_configure() {
	local myconf=(
		--enable-maintainer-mode # git source code doesn't comes with generated files, for example. glib-genmarshal only running in maintainer mode
		$(use_enable curl cover-thumbnailer)
		$(use_enable epub gepub-thumbnailer)
		$(use_enable jpeg jpeg-thumbnailer)
		$(use_enable ffmpeg ffmpeg-thumbnailer)
		$(use_enable gstreamer gstreamer-thumbnailer)
		$(use_enable odf odf-thumbnailer)
		$(use_enable pdf poppler-thumbnailer)
		$(use_enable raw raw-thumbnailer)
	)
	econf "${myconf[@]}"
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}