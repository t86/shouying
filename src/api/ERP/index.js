/**
 * 仓库管理 ERP
**/
// this.$api.ERP.sin 


import home from "./home"               // home           首页
import supplier from "./supplier"       // supplier       供应商
import store from "./store"             // store          epr仓库
import mocate from "./mocate"           // mocate         物料一级分类
import mtcate from "./mtcate"           // mtcate         物料二级分类
import mcate from "./mcate"             // mcate          物料分类树
import mat_unit from "./mat_unit"       // mat_unit       物料单位
import mat_spec from "./mat_spec"       // mat_spec       物料规格
import mat from "./mat"                 // mat            物料管理
import sin from "./sin"                 // sin            采购入库,其他入库
import sout from "./sout"               // sout           销售出库,其他出库
import sind from "./sind"               // sind           调拨入库
import soutd from "./soutd"             // soutd          调拨出库
import soutdd_yy from "./soutdd_yy"     // soutdd_yy      异议处理
import rpt_erp from "./rpt_erp"         // rpt_erp        rpt_erp ERP报表
import comparePrd from "./comparePrd"   // comparePrd        商品对照
import erpLib from "./erpLib"           // erpLib        物料实时库存表
import emptyLib from "./emptyLib"           // emptyLib        空瓶管理
import reportEmpty from "./reportEmpty"  // reportEmpty   空瓶出入库明细表      

export default {
    home,
    supplier,
    store,
    mocate,
    mtcate,
    mcate,
    mat_unit,
    mat_spec,
    mat,
    sin,
    sout,
    sind,
    soutd,
    soutdd_yy,
    rpt_erp,
    comparePrd,
    erpLib,
    emptyLib,
    reportEmpty
};