//加载path模块
const path = require("path");
//定义resolve方法，把相对路径转换成绝对路径
const resolve = (dir) => path.join(__dirname, dir);
//版本号
const packageJson = require("./package.json");

const VersionPlugin = require("./src/utils/versionPlugin.js");
module.exports = {
  devServer: {
    host: "0.0.0.0", // 主机地址
    port: 8090, // 端口号
  },
  publicPath: "/shouyin/",
  outputDir: "dist",
  // 不需要报错信息 如果您不需要生产时的源映射，那么将此设置为false可以加速生产构建
  productionSourceMap: false,
  filenameHashing: false, // 打包的时候不使用hash值.因为我们有版本号来确定项目的唯一性了.
  //
  configureWebpack: {
    //重点
    output: {
      // 输出重构 打包编译后的js文件名称,添加版本号.
      filename: `js/[name].${packageJson.version}.js`,
      chunkFilename: `js/[name].${packageJson.version}.js`,
    },
    devtool: process.env.NODE_ENV === 'production' ? false : 'source-map',
    optimization: {
      runtimeChunk: 'single',
      moduleIds: 'hashed',
      splitChunks: {
        chunks: 'all',
        maxInitialRequests: 3,
        minSize: 20000,
        maxSize: 250000,
        minChunks: 1,
        maxAsyncRequests: 30,
        maxInitialRequests: 30,
        automaticNameDelimiter: '~',
        cacheGroups: {
          // 基础框架包 - 必须首屏加载
          framework: {
            name: 'framework',
            test: /[\\/]node_modules[\\/](vue|vue-router|vuex)[\\/]/,
            priority: 100,
            chunks: 'initial',
            enforce: true
          },
          // 首屏必需组件
          initial: {
            name: 'initial',
            test: /[\\/]src[\\/](views|components)[\\/](home|Thelogin|Register)[\\/]/,
            priority: 90,
            chunks: 'initial',
            enforce: true
          },
          // 其他所有包异步加载
          vendors: {
            name(module) {
              const packageName = module.context.match(/[\\/]node_modules[\\/](.*?)([\\/]|$)/)[1];
              return `npm.${packageName.replace('@', '')}`;
            },
            test: /[\\/]node_modules[\\/]/,
            priority: 80,
            chunks: 'async'
          }
        }
      }
    },
    performance: {
      hints: 'warning',
      maxEntrypointSize: 250000,
      maxAssetSize: 250000
    },
  },

  css: {
    //重点.
    extract: {
      // 打包后css文件名称添加版本号
      filename: `css/[name].${packageJson.version}.css`,
      chunkFilename: `css/[name].${packageJson.version}.css`,
    },
    loaderOptions: {
      postcss: {
        plugins: [
          require('tailwindcss'),
          require('autoprefixer')
        ]
      }
    }
  },
  chainWebpack: (config) => {
    // 解决 页面中的空格占位符被清除的问题
    config.module
      .rule("vue")
      .use("vue-loader")
      .loader("vue-loader")
      .tap((options) => {
        options.compilerOptions.whitespace = "preserve";
        return options;
      })
      .end();
    // 添加别名
    config.resolve.alias.set("@", resolve("src"));

  // 移除 prefetch
  config.plugins.delete('prefetch');
      
  // 只预加载首屏必需资源
  config.plugin('preload').tap(options => {
    options[0].include = 'initial';
    // 确保包含运行时代码
    options[0].fileBlacklist = [/\.map$/, /hot-update\.js$/];
    return options;
  });
    config
      .plugin("version")
      .use(VersionPlugin)
      .tap((args) => {
        return args;
      });

    // 设置图片不转base64
    config.module
      .rule("images")
      .use("url-loader")
      .loader("url-loader")
      .tap((options) => Object.assign(options, { limit:  1 }));
  },
};
