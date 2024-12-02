
export const projectName = process.env.VUE_APP_PROJECT_NAME
export const projectConfig = {
  // 开发环境 外网可以直接访问
  'dev': {
    username: '000000',
    password: '666666',

    // 开发测试环境的hosts配置： 10.118.128.1      nls.server.com
    development: 'https://nls-dev.xmsjznwl.com/server',
    product: 'https://nls-dev.xmsjznwl.com/server',
    onlineBase:'https://ncrmyun-dev.xmsjznwl.com/server',
    wsDevelopment: 'wss://nls-dev.xmsjznwl.com/server',
    wsProduct: 'wss://nls-dev.xmsjznwl.com/server'
  },
  // 开发环境 本地访问
  'local': {
    username: '000000',
    password: '666666',

    // 开发测试环境的hosts配置： 10.118.128.1      nls.server.com
    development: 'https://nls.server.com/server',
    product: 'https://nls.server.com/server',
    onlineBase:'https://ncrmyun-dev.xmsjznwl.com/server',
    wsDevelopment: 'wss://nls.server.com/server',
    wsProduct: 'wss://nls.server.com/server'
  },
  // 门店生产环境
  'store': {
    username: '',
    password: '',
    development: 'http://nls.server.com/server',
    product: 'http://nls.server.com/server',
    onlineBase:'https://ncrmyun.xmsjznwl.com/server',
    wsDevelopment: 'ws://nls.server.com/server',
    wsProduct: 'ws://nls.server.com/server'
  },
}