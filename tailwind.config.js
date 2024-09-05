module.exports = {
  purge: [
    './src/**/*.html',
    './src/**/*.vue',
    './src/**/*.jsx',
  ],
  theme: {
    extend: {}
  },
  variants: {},
  plugins: [],
  corePlugins: {
    preflight: false, // 禁用Tailwind的基础样式重置
  }
}
