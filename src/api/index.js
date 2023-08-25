/** 
 * api接口的统一出口
 */
// 后台管理系统
import BMS from '@/api/BMS';
// ERP管理系统
import ERP from '@/api/ERP';
// 工具 登录
import UtilAuth from '@/api/UtilAuth';


// 其他系统的接口……




// 导出接口
export default {    
    BMS,
    UtilAuth,
    ERP,
    // ……
}