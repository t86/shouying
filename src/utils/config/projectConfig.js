
export const projectName = 'dev'

export const projectConfig = {
  // 开发环境
  'dev': {
    username: '000000',
    password: '666666',

    // 开发测试环境的hosts配置： 10.118.128.1      nls.server.com
    development: 'http://nls.server.com/server',
    product: 'http://nls.server.com/server',
    onlineBase:'https://ncrmyun-dev.xmsjznwl.com/server',
    wsDevelopment: 'ws://nls.server.com/server',
    wsProduct: 'ws://nls.server.com/server'
  },
  // 门店生产环境
  'store': {
    username: '',
    password: '',
    development: 'http://nls.server.com/server',
    product: 'http://nls.server.com/server',
    // onlineBase:'https://ncrm-server-tmp.830clock.com/server',
    onlineBase:'https://ncrmyun.xmsjznwl.com/server',
    wsDevelopment: 'ws://nls.server.com/server',
    wsProduct: 'ws://nls.server.com/server'
  },
}