# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Image Viewer"
HOMEPAGE="https://gitlab.xfce.org/apps/ristretto"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/25/repository/archive.tar.bz2?sha=ristretto-0.13.1 -> ristretto-0.13.1.tar.bz2"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=dev-libs/glib-2.56.0:2
	>=media-libs/libexif-0.6.0
	>=x11-libs/cairo-1.10.0
	>=x11-libs/gtk+-3.22.0:3
	>=xfce-base/libxfce4ui-4.16.0
	>=xfce-base/libxfce4util-4.16.0
	>=xfce-base/xfconf-4.12.1
	"


# 	sys-apps/file is in @system set


DEPEND="${RDEPEND}"

BDEPEND="
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig"

post_src_unpack() {
	if [ ! -d "${S}" ] ; then
		mv "${WORKDIR}"/${PN}-* "${S}" || die
	fi
}

src_prepare() {
	sed -i "s/XDT_AUTOGEN_REQUIRED_VERSION=\"4\\.17\\.1\"/XDT_AUTOGEN_REQUIRED_VERSION=\"4\\.16\\.0\"/g" autogen.sh # in configure.ac 4.16.0 was requested
	NOCONFIGURE=1 ./autogen.sh
	default
	eautoreconf
}

src_configure() {
        local myconf=(
		--enable-maintainer-mode # git source code doesn't comes with generated files, for example. glib-genmarshal only running in maintainer mode
		--with-x
	)
        econf "${myconf[@]}"
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
