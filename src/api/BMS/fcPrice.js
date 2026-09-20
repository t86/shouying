import base from '../base';
import http from '../../utils/http';

export default {
  products: data => http.post(`${base.htgl}/prd/get_fc_prd_cfg_list`, data),
  productItems: data => http.post(`${base.htgl}/prd/get_fc_prd_cfg_items`, data),
  addProducts: data => http.post(`${base.htgl}/prd/batch_add_fc_prd`, data),
  deleteProducts: data => http.post(`${base.htgl}/prd/batch_del_fc_prd`, data),
  plans: () => http.post(`${base.htgl}/prd/get_fc_price_plan_list`, {}),
  employeeItems: data => http.post(`${base.htgl}/prd/get_fc_plan_emp_items`, data),
  removeEmployee: data => http.post(`${base.htgl}/prd/remove_emp_from_plan`, data),
  addPlan: data => http.post(`${base.htgl}/prd/new_fc_price_plan`, data),
  deletePlans: data => http.post(`${base.htgl}/prd/batch_del_fc_price_plan`, data),
  savePlan: data => http.post(`${base.htgl}/prd/save_fc_price_plan`, data),
  savePrice: data => http.post(`${base.htgl}/prd/save_fc_prd_plan_price`, data),
};
