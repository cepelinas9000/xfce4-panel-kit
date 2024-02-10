# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION=""
HOMEPAGE="https://gitlab.xfce.org/panel-plugins/xfce4-pulseaudio-plugin"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/61/repository/archive.tar.bz2?sha=xfce4-pulseaudio-plugin-0.4.8 -> xfce4-pulseaudio-plugin-0.4.8.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=dev-libs/glib-2.42.0:2
	>=media-sound/pulseaudio-0.9.19
	>=x11-libs/gtk+-3.20.0:3
	>=xfce-base/exo-0.11.0
	>=xfce-base/libxfce4ui-4.11.0
	>=xfce-base/libxfce4util-4.9.0
	>=xfce-base/xfce4-panel-4.11.0
	>=xfce-base/xfconf-4.6.0"

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