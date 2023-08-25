import { projectName, projectConfig } from '@/utils/config/projectConfig.js'
/**
 * 接口域名的管理
 */

const base = {    

  htgl:process.env.NODE_ENV === 'development'? projectConfig[projectName]['development'] : projectConfig[projectName]['product'],
  
  // 小程序
  onlineBase: projectConfig[projectName]['onlineBase'],
  /**
  * websocket 获取卡台相关信息
  */
 	cardWebsocketPath: process.env.NODE_ENV === 'development' ? projectConfig[projectName]['wsDevelopment'] : projectConfig[projectName]['wsProduct'],
 	// cardWebsocketPath: 'http://10.200.103.105:8230',

}
export default base;