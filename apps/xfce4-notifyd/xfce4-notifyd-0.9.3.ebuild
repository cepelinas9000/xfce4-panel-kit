# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Easily themable notification daemon with transparency effects"
HOMEPAGE="https://gitlab.xfce.org/apps/xfce4-notifyd"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/31/repository/archive.tar.bz2?sha=xfce4-notifyd-0.9.3 -> xfce4-notifyd-0.9.3.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"
IUSE="sound wayland X"

RDEPEND=">=dev-libs/glib-2.56.0:2
	>=x11-libs/libnotify-0.7.0
	>=x11-libs/gtk+-3.22:3[wayland?,X?]
	>=xfce-base/libxfce4ui-4.12.0
	>=xfce-base/libxfce4util-4.12.0
	>=xfce-base/xfce4-panel-4.12.0
	>=xfce-base/xfconf-4.10.0
	sound? ( >=media-libs/libcanberra-0.30[gtk3] )
	wayland? ( >=gui-libs/gtk-layer-shell-0.7.0 )
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
	sed -i "s/XDT_AUTOGEN_REQUIRED_VERSION=\"4\\.17\\.1\"/XDT_AUTOGEN_REQUIRED_VERSION=\"4\\.16\\.0\"/g" autogen.sh # in configure.ac older version were requested
	NOCONFIGURE=1 ./autogen.sh
	default
	eautoreconf
}

src_configure() {
        local myconf=(
		--enable-maintainer-mode # git source code doesn't comes with generated files, for example. glib-genmarshal only running in maintainer mode
		$(use_enable wayland gdk-wayland)
		$(use_enable wayland gtk-layer-shell)
		$(use_enable X gdk-x11)
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