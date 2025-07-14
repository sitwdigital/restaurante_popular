import AuthLogo from './extensions/logo.svg';
import MenuLogo from './extensions/logo.svg';
import favicon from './extensions/logo.svg';

export default {
  config: {
    auth: {
      logo: AuthLogo,
    },
    menu: {
      logo: MenuLogo,
    },
    head: {
      favicon: favicon,
      title: 'Restaurante Popular Maranhão', // ✅ <-- aqui você coloca o nome do projeto
    },
    theme: {
      colors: {
        primary100: '#ffe6e6',
        primary200: '#ffcccc',
        primary500: '#e30613',
        primary600: '#cc0611',
        primary700: '#99050d',
      },
    },
    translations: {
      pt: {
        'app.components.LeftMenu.navbrand.title': 'Restaurante Popular',
        'app.components.LeftMenu.navbrand.workplace': 'Painel',
      },
    },
  },
  bootstrap() {},
};
