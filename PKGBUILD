pkgname=easy-config
pkgver=1.1.0
pkgrel=1
pkgdesc="Simple CLI tool to quickly open and edit configuration files"
arch=('any')
url="https://github.com/keegang6705/EasyConfig"
license=('MIT')
depends=()
optdepends=('fzf: for interactive selection'
            'fd: for faster file searching'
            'bash-completion: for bash completion'
            'zsh: for zsh completion'
            'fish: for fish completion')
source=("cf.sh" "cf-setup.sh" "config.conf" "LICENSE" "completions/cf.bash" "completions/cf.zsh" "completions/cf.fish")
sha256sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
    install -Dm755 cf.sh "$pkgdir/usr/local/bin/cf"
    install -Dm755 cf-setup.sh "$pkgdir/usr/local/bin/cf-setup"
    install -Dm644 config.conf "$pkgdir/etc/easy-config/config.conf"
    install -Dm444 config.conf "$pkgdir/usr/share/easy-config/config.conf.default"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    install -Dm644 cf.bash "$pkgdir/usr/share/bash-completion/completions/cf"
    install -Dm644 cf.zsh "$pkgdir/usr/share/zsh/site-functions/_cf"
    install -Dm644 cf.fish "$pkgdir/usr/share/fish/vendor_completions.d/cf.fish"
}
