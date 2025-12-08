import base from '../../base.js';
import axios from '../../../utils/http.js';

const businessEmp = {
  // 获取商务组订位人列表
  reqGetBsSalesList(data) {
    return axios.post(`${base.htgl}/emp/get_bs_sales_list`, data);
  },

  // 批量添加商务组订位人
  reqBatchAddBsSales(data) {
    return axios.post(`${base.htgl}/emp/batch_add_bs_sales`, data);
  },

  // 删除商务组订位人
  reqRemoveBsSales(data) {
    return axios.post(`${base.htgl}/emp/remove_bs_sales`, data);
  },
};

export default businessEmp;











