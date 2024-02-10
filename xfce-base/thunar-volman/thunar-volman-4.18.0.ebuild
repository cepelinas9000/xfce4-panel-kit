# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Automatic management of removable drives and media for Thunar"
HOMEPAGE="https://gitlab.xfce.org/xfce/thunar-volman"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/9/repository/archive.tar.bz2?sha=thunar-volman-4.18.0 -> thunar-volman-4.18.0.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"
IUSE="libnotify"

RDEPEND=">=dev-libs/glib-2.66.0:2
	>=dev-libs/libgudev-145
	>=x11-libs/gtk+-3.24.0:3
	>=xfce-base/exo-0.10.0
	>=xfce-base/libxfce4ui-4.12.0
	>=xfce-base/libxfce4util-4.12.0
	>=xfce-base/xfconf-4.12.0
	libnotify? ( >=x11-libs/libnotify-0.7 )
	virtual/udev
	>=xfce-base/thunar-1.6[udisks]
	"

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
	NOCONFIGURE=1 ./autogen.sh
	default
	eautoreconf
}

src_configure() {
        local myconf=(
		--enable-maintainer-mode # git source code doesn't comes with generated files, for example. glib-genmarshal only running in maintainer mode
                $(use_enable libnotify notifications)
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