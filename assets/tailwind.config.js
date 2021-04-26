module.exports = {
  purge: [
    '../lib/coin_purse_web/**/*.ex',
    '../lib/coin_purse_web/**/*.leex',
    '../lib/coin_purse_web/**/*.eex',
    './js/**/*.js'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      colors: {},
    },
  },
  variants: {},
  plugins: [],
}
