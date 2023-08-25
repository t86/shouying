import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {
  // Org 门店管理
  // 获取门店信息
  reqGetDetailInfo(data) {
    return axios.post(`${base.htgl}/org/get_info`, data);
  },

  // 读取省市列表
  reqGetCityList(data) {
    return axios.post(`${base.htgl}/cfg/addr/provinces`, data);
  },

  // 根据市读取区列表
  reqGetCountyList(data) {
    return axios.post(`${base.htgl}/cfg/addr/districts`, data);
  },

  // 保存门店信息
  reqSubmitInfo(data) {
    return axios.post(`${base.htgl}/org/save_info`, data);
  },


  // 通过百度地图检索相应的详细地址列表
  reqGetAddressList: params => axios.post(`${base.htgl}/util/suggestion`, params),


  // 通过百度地图地址获取经纬度
  reqGetLatAndLng: params => axios.post(`${base.htgl}/util/geocoding`, params)

}
export default article;