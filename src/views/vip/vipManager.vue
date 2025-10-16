<template>
  <div class="vip vip-manager" @click.stop="rightClickHandle($event, {})">
    <h3 class="title">会员管理</h3>

    <div class="search m-t-2 m-b-4">
      <div class="row">
        <span class="label">出生月份:</span>
        <el-date-picker style="width:130px" v-model="form.begin_birth_day" type="date" :clearable="false" size="small"
          value-format="yyyy-MM-dd" placeholder="开始日期"></el-date-picker>
        <span>至</span>
        <el-date-picker style="width:130px" v-model="form.end_birth_day" type="date" :clearable="false" size="small"
          value-format="yyyy-MM-dd" placeholder="结束日期"></el-date-picker>
      </div>
      <div class="row">
        <span class="label">卡类型:</span>
        <el-select v-model="form.typeVal" size="small" placeholder="请选择卡类型" style="width: 200px">
          <el-option v-for="item in form.typeOption" :key="item.id" :label="item.n" :value="item.id">
          </el-option>
        </el-select>
      </div>
      <div class="row">
        <span class="label">等&nbsp;&nbsp;&nbsp;&nbsp;级:</span>
        <el-select v-model="form.deepVal" size="small" placeholder="请选择等级" style="width: 200px">
          <el-option v-for="item in form.deepOption" :key="item.id" :label="item.n" :value="item.id">
          </el-option>
        </el-select>
      </div>
      <div class="row">
        <span class="label">开卡推荐人:</span>
        <el-select style="width: 216px" v-model="form.personVal" filterable remote reserve-keyword
          placeholder="输入员工姓名或工号可查询" :remote-method="remoteMethod" :loading="remoteLoading" size="small">
          <el-option v-for="item in personOptions" :key="item.id" :label="item.name + ' (' + item.code + ')'"
            :value="item.id"></el-option>
        </el-select>
      </div>
      <div class="row" layout="row" layout-align="start center">
        <el-input 
          class="m-r-2" 
          v-model="form.keyword" 
          size="small" 
          placeholder="姓名/手机号(支持11位)/会员卡号"
          style="width: 480px"
          @keyup.enter="getTableData"
          clearable
        ></el-input>
        <button class="btn primary m-l-4" @click="getTableData">查询</button>
        <button class="btn info m-l-4" @click="resetHandle">重置</button>
        <button class="btn info m-l-4" @click="exportExcel">导出</button>
      </div>
    </div>

    <div class="top" layout="row" layout-align="start center">
      <icon-button v-if="hasAddOrEditAuth" @click.native="showOrHideAddVipDrawerHandle" text="新增" img="btn_add.png"
        bjcolors="#DDE0E9" bcolor="#8c8c8c"></icon-button>
      <characters-button v-if="$store.getters.vipAuth" @click.native="showOrHideAddMoneyToVipDrawerHandle"
        bjcolors="#DDE0E9" bcolor="#8c8c8c" wz="充值"></characters-button>
      <characters-button @click.native="showOrHideReadCardDrawerHandle" bjcolors="#DDE0E9" bcolor="#8c8c8c"
        wz="读取卡信息"></characters-button>
      <characters-button v-if="hasAddOrEditAuth" @click.native="showOrHidePayNumSearchDrawerHandle" bjcolors="#DDE0E9"
        bcolor="#8c8c8c" wz="付款序列号制卡"></characters-button>
    </div>

    <!-- table -->
    <div class="contain">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">操作</div>
            <div class="th">序号</div>
            <div class="th">姓名</div>
            <div class="th">状态</div>
            <div class="th">绑定手机</div>
            <div class="th">联系手机</div>
            <div class="th">性别</div>
            <div class="th">出生日期</div>
            <div class="th">会员卡号</div>
            <div class="th">会员卡类型</div>
            <div class="th">卡等级</div>
            <div class="th">会员标签</div>
            <div class="th">总余额</div>
            <div class="th">积分</div>
            <div class="th">开卡推荐人</div>
            <div class="th">最后消费日期</div>
            <div class="th">注册日期</div>
            <div class="th">到期日期</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="(item, index) in tableData" :key="index" layout="row" layout-align="space-between center"
            @click.right.prevent.stop="rightClickHandle($event, item)">
            <div class="td">
              <span @click="preVipDetail(item)">查看详情</span>
            </div>
            <div class="td">{{ index + 1 }}</div>
            <div class="td">{{ item.n }}</div>
            <div class="td status-column">{{ item.sn }}</div>
            <div class="td" @click.stop="copyText(item.bp)">{{ item.bp }}</div>
            <div class="td" @click.stop="copyText(item.cp)">{{ item.cp }}</div>
            <div class="td">{{ item.s }}</div>
            <div class="td">{{ item.b }}</div>
            <div class="td" layout="row" layout-align="start center">
              <span>{{ item.cn }}</span>
              <img v-if="item.h == 1" :src="require('@/assets/vip-imgs/vip-manager-icon.png')" />
            </div>
            <div class="td">{{ item.ct }}</div>
            <div class="td">{{ item.cl }}</div>
            <div class="td">{{ item.m }}</div>
            <div class="td fs16-bold">{{ item.ba }}</div>
            <div class="td">{{ item.p }}</div>
            <div class="td">{{ item.se }}</div>
            <div class="td">{{ item.lc }}</div>
            <div class="td">{{ item.r }}</div>
            <div class="td">{{ item.e }}</div>

            <div class="sj" v-if="item.showTips" :style="{ left: item.pointerX - 20 + 'px' }"></div>
            <ul class="tips" v-if="item.showTips" :style="{
              left: item.pointerX + 65 + 'px',
              transform: 'translate(-50%,' + item.disY * -1 + 'px)',
            }">
              <li class="item" v-for="items in item.tipsList" :key="items.id" @click="clickOptionHandle(item, items)">
                <div>{{ items.name }}</div>
              </li>
            </ul>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img :src="require('@/assets/vip-imgs/empty.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
    <div class="pagination">
      <el-pagination background layout="prev, pager, next" :total="pageInfo.total" :page-size="pageInfo.pageSize"
        :current-page="pageInfo.page" @current-change="changePageHandle">
      </el-pagination>
    </div>

    <!-- 添加会员 -->
    <drawerAddVip :showDrawer="showAddVipDrawer" :initStep="initStep" :initVipId="currentVipId"
      @showOrHideDrawer="showOrHideAddVipDrawerHandle" @showOrHideModalHandle="showOrHideModalHandle"
      @changeInitStep="changeInitStep" @updateVipIdHandle="updateVipIdHandle" @getTableData="getTableData" />
    <!-- 修改表格中的会员相关option信息操作 -->
    <drawerOptionEvent :showDrawer="showOptionDrawer" :optionObj="optionObj" @getTableData="getTableData"
      @showOrHideDrawer="showOrHideOptionDrawerHandle" />
    <!-- 会员充值 -->
    <drawerAddMoneyToVip :showDrawer="showAddMoneyToVipDrawer" :currentVipId="currentVipId" @getTableData="getTableData"
      @showOrHideDrawer="showOrHideAddMoneyToVipDrawerHandle" />
    <!-- 会员卡识别 -->
    <drawerReadCard :showDrawer="showReadCardDrawer" @showOrHideDrawer="showOrHideReadCardDrawerHandle"
      @updateVipDetailHandle="preVipDetail" />
    <!-- 付款序列号搜索制卡 -->
    <drawerPayNumSearch :showDrawer="showPayNumDrawer" @showOrHideDrawer="showOrHidePayNumSearchDrawerHandle"
      @updateCurrentVipInfo="updateCurrentVipInfo" />
    <!-- 会员详情 -->
    <drawerVipDetail :showDrawer="showVipDetailDrawer" :preVipInfo="preVipInfo"
      @showOrHideDrawer="showOrHideVipDetailDrawerHandle" />
    <!-- 提示框 -->
    <modalCom :showModal="modalInfo.showModal" :modalText="modalInfo.modalText" :iconText="modalInfo.iconText"
      :btnText="modalInfo.btnArr" @showOrHideModal="showOrHideModalHandle" @centerBtnClick="addMoneyToVipCardHandle"
      @submitBtnClick="modelSubmitHandle" @getData="getTableData" />
  </div>
</template>

<script>
import api_vip from "@/api/vip";
import IconButton from "@/components/IconButton.vue";
import CharactersButton from "@/components/CharactersButton.vue";
import drawerAddVip from "@/components/vip/vipManager/drawerAddVip/index.vue";
import drawerAddMoneyToVip from "@/components/vip/vipManager/drawerAddMoneyToVip/index.vue";
import drawerReadCard from "@/components/vip/vipManager/drawerReadCard/index.vue";
import drawerPayNumSearch from "@/components/vip/vipManager/drawerPayNumSearch/index.vue";
import drawerVipDetail from "@/components/vip/vipManager/drawerVipDetail/index.vue";
import drawerOptionEvent from "@/components/vip/vipManager/drawerOptionEvent/index.vue";
import modalCom from "@/components/vip/common/modal.vue";

import tipsArr from "@/components/vip/vipManager/drawerOptionEvent/tipsArr";
import { copyToClip } from "@/utils/copy"
export default {
  data() {
    return {
      form: {
        begin_birth_day: "",
        end_birth_day: "",
        typeVal: "",
        typeOption: [],
        deepVal: "",
        deepOption: [],
        keyword: "",
        personVal: "",
      },
      remoteLoading: false,
      tableData: [],
      showAddVipDrawer: false,
      showOptionDrawer: false, // 是否显示table中option相关操作
      showAddMoneyToVipDrawer: false,
      showReadCardDrawer: false,
      showPayNumDrawer: false,
      showVipDetailDrawer: false,
      initStep: 1, // 作用：1、初始化页面step  2、记录关闭step drawer时记录时的step
      currentVipId: "",

      preVipInfo: {}, // 当前查看会员详情的vip数据

      optionObj: {
        currentInfo: {},
        optionInfo: {},
      },

      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0,
      },
      modalInfo: {
        showModal: false,
        iconText: "success",
        modalText: "新增成功，5秒后将关闭",
        btnArr: ["关闭", "充值", "制卡"],
      },
      personOptions: [], //开卡推荐人
    };
  },
  mounted() {
    document.onkeydown = this.keyHandle
  },
  beforeDestroy() {
    document.onkeydown = null
  },
  methods: {

    keyHandle(e) {
      if (e.keyCode == 13) {
        this.getTableData(true)
      }
    },
    copyText(text) {
      if (!text) return
      try {
        copyToClip(text);
        this.$message.success('复制成功')
      } catch {
        this.$message.success('复制失败')
      }


    },
    async getTableData(rest = false) {
      if (rest) this.pageInfo.page = 1;
      
      // 🔍 手机号搜索优化
      const keyword = this.form.keyword.trim();
      if (keyword && this.isPhoneNumber(keyword)) {
        console.log("🎯 [会员搜索] 检测到手机号搜索:", keyword);
        if (keyword.length !== 11) {
          this.$message.warning("请输入完整的11位手机号");
          return;
        }
      }
      
      const params = {
        page_num: this.pageInfo.page, //   int   第几页
        page_size: this.pageInfo.pageSize, //  int     每页行数
        is_init: rest ? 1 : 2, //    int    1 初始化,会返回会员类型及会员等级列表 2 非初始化
        begin_birth_day: this.form.begin_birth_day || "", // string   生日月份与日期(开始),格式 mm-dd 不过滤,传空
        end_birth_day: this.form.end_birth_day || "", // string  生日月份与日期(结束,包含),格式 mm-dd 不过滤,传空
        card_type_id: this.form.typeVal, // int64    卡类型Id
        card_level_id: this.form.deepVal, // int64   卡等级Id
        key: keyword, //    string    关键字, 姓名/手机号/会员卡号
        sales_emp_id: this.form.personVal * 1, // string 开卡推荐人关键字
      };
      
      console.log("🎯 [会员搜索] 开始请求，参数:", params);
      console.log("🎯 [会员搜索] 是否初始化:", rest ? "是" : "否");
      
      try {
        const res = await api_vip.reqGetVipCardList(params);
        console.log("✅ [会员搜索] 请求成功，响应:", res);
        if (res.code == 1) {
          this.form.typeOption = res.data.card_types || [];
          this.pageInfo.total = res.data.row_cnt || 0;
          this.tableData = (res.data.records || []).map((item) => ({
            ...item,
            tipsList: this.getTipsList(item.h, item.sn),
            showTips: false,
            pointerX: 0,
          }));
          
          // 🎯 搜索结果提示
          if (keyword && this.isPhoneNumber(keyword)) {
            console.log("🎯 [会员搜索] 手机号搜索结果数量:", this.tableData.length);
            if (this.tableData.length === 0) {
              this.$message.info("未找到该手机号对应的会员信息");
            } else {
              this.$message.success(`找到 ${this.tableData.length} 条相关会员信息`);
            }
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        // 如果是请求被取消（频率限制），不显示错误提示
        if (error.__CANCEL__ || error.message === '请求频率过快，已自动拦截') {
          console.warn("⚠️ [会员管理] 请求被拦截，不显示错误提示");
          return;
        }
        
        console.error("🚨 [会员管理] 获取表格数据失败:", error);
        console.error("🚨 [会员管理] 错误详情:", error.response || error.message);
        console.error("🚨 [会员管理] 请求参数:", params);
        
        // 显示更详细的错误信息
        const errorMsg = (error.response && error.response.data && error.response.data.msg) || error.message || "网络连接失败";
        this.$message.error(`获取会员列表失败: ${errorMsg}`);
      }
    },
    async exportExcel() {
      const params = {
        begin_birth_day: this.form.begin_birth_day || "", // string   生日月份与日期(开始),格式 mm-dd 不过滤,传空
        end_birth_day: this.form.end_birth_day || "", // string  生日月份与日期(结束,包含),格式 mm-dd 不过滤,传空
        card_type_id: this.form.typeVal, // int64    卡类型Id
        card_level_id: this.form.deepVal, // int64   卡等级Id
        key: this.form.keyword, //    string    关键字, 姓名/手机号/会员卡号
        sales_emp_id: this.form.personVal * 1, // string 开卡推荐人关键字
      };
      try {
        const res = await api_vip.reqExportExcelForVipManager(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            })
          );
          const a = document.createElement("a"); //添加a标签
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", decodeURIComponent(res.fileName)); // 下载文件的名称及文件类型后缀
          a.click(); //点击标签
          document.body.removeChild(a); // 下载完成移除元素
          window.URL.revokeObjectURL(url); // 释放掉blob对象
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("导出excel失败", error);
      }
    },
    // 获取右击菜单列表
    getTipsList(type, sn) {
      const makedCardList = [1, 3, 4, 5, 6, 7, 8, 10, 11, 9];
      const notMakedCardList = [1, 2, 3, 4, 8, 10, 11, 9];
      let list = tipsArr;
      if (!this.$store.getters.vipAuth) {
        list = tipsArr.filter((item) =>
          [1, 3, 4, 5, 6, 7, 9].includes(item.id)
        );
      }
      if (!this.hasAddOrEditAuth) {
        list = list.filter((item) => ![1, 2, 3, 4, 5, 6, 7, 9].includes(item.id));
      }
      
      console.log("type", type);
      // 根据状态过滤冻结/解冻选项
      const isLocked = (sn === "冻结");
      console.log("sn", sn);
      console.log("isLocked", isLocked);
      
      let result = list.filter((item) =>
        type == 1
          ? makedCardList.includes(item.id)
          : notMakedCardList.includes(item.id)
      );
         // 添加冻结/解冻选项
      if (isLocked) {
                // 如果是正常状态，添加冻结选项
                result.push({   
          id: 13,
          objName: "unlockVipCardInfoObj",
          name: "解冻"});
                  // 如果是已冻结状态，添加解冻选项
      } else {
        result.push({
          id: 12,
          objName: "lockVipCardInfoObj",
          name: "冻结",
        });
      }
      console.log("result", result);
      return result;
    },
    rightClickHandle(e, itemInfo) {
      // 判断是否是收银系统进入

      const minY = 350;
      const pointerY = e.pageY;
      const disY = Math.min(pointerY - minY + 40, 90);
      const pointerX = e.pageX;
      itemInfo.pointerX = pointerX;
      const tableData = [...this.tableData];
      this.tableData = tableData.map((item) => ({
        ...item,
        showTips: item.id == itemInfo.id,
        pointerX: item.id == itemInfo.id ? pointerX : 0,
        disY: item.id == itemInfo.id ? disY : 0,
      }));
      this.$forceUpdate();
    },
    resetHandle() {
      this.form = {
        begin_birth_day: "",
        end_birth_day: "",
        typeVal: "",
        typeOption: [],
        deepVal: "",
        deepOption: [],
        keyword: "",
      };
      this.getTableData(true);
    },
    // table表格option
    async clickOptionHandle(itemInfo, optionInfo) {
      // 处理冻结/解冻操作
      if (optionInfo.id === 12) {
        // 冻结操作
        try {
          const params = {
            mb_card_id: itemInfo.id
          };
          const res = await api_vip.reqLockVipCard(params);
          if (res.code === 1) {
            this.$message.success('冻结成功');
            this.getTableData(); // 刷新表格数据
          } else {
            this.$message.warning(res.msg || '冻结失败');
          }
        } catch (error) {
          console.error('冻结会员卡失败', error);
          this.$message.error('冻结会员卡失败');
        }
        return;
      } else if (optionInfo.id === 13) {
        // 解冻操作
        try {
          const params = {
            mb_card_id: itemInfo.id
          };
          const res = await api_vip.reqUnlockVipCard(params);
          if (res.code === 1) {
            this.$message.success('解冻成功');
            this.getTableData(); // 刷新表格数据
          } else {
            this.$message.warning(res.msg || '解冻失败');
          }
        } catch (error) {
          console.error('解冻会员卡失败', error);
          this.$message.error('解冻会员卡失败');
        }
        return;
      }
      
      // 原有的处理逻辑
      this.optionObj.currentInfo = { ...itemInfo };
      this.optionObj.optionInfo = { ...optionInfo };
      this.showOrHideOptionDrawerHandle();
    },
    showOrHideAddVipDrawerHandle() {
      this.showAddVipDrawer = !this.showAddVipDrawer;
      if (!this.showAddVipDrawer) {
        setTimeout(() => {
          if (!this.modalInfo.showModal) {
            this.changeInitStep(1);
            this.updateVipIdHandle("");
          }
        }, 1000);
      }
    },
    showOrHideOptionDrawerHandle() {
      this.showOptionDrawer = !this.showOptionDrawer;
    },
    showOrHideAddMoneyToVipDrawerHandle() {
      this.showAddMoneyToVipDrawer = !this.showAddMoneyToVipDrawer;
    },
    showOrHideReadCardDrawerHandle() {
      this.showReadCardDrawer = !this.showReadCardDrawer;
    },
    showOrHidePayNumSearchDrawerHandle() {
      this.showPayNumDrawer = !this.showPayNumDrawer;
    },
    showOrHideVipDetailDrawerHandle() {
      this.showVipDetailDrawer = !this.showVipDetailDrawer;
    },
    changePageHandle(page = 1) {
      this.pageInfo.page = page;
      this.getTableData();
    },
    updateVipIdHandle(vipId) {
      this.currentVipId = vipId;
    },
    updateCurrentVipInfo({ info, optionInfo }) {
      this.clickOptionHandle(info, optionInfo);
    },
    changeInitStep(step) {
      this.initStep = step;
    },
    // 查看会员详情
    preVipDetail(itemInfo) {
      this.preVipInfo = { ...itemInfo };
      this.showOrHideVipDetailDrawerHandle();
    },
    /*
      modal相关
    */
    // modal中间提交按钮
    addMoneyToVipCardHandle() {
      this.showOrHideAddMoneyToVipDrawerHandle();
      this.showOrHideModalHandle();
    },
    // modal右边提交
    modelSubmitHandle() {
      if (this.initStep == 3) {
        // 记名卡添加vip完成，去制卡
        this.changeInitStep(4);
        this.showOrHideAddVipDrawerHandle();
        this.showOrHideModalHandle();
      } else {
        // 制卡成功(此时无中间按钮)，去充值
        this.addMoneyToVipCardHandle();
      }
    },
    // modal取消按钮
    showOrHideModalHandle(modalObjInfo = {}) {
      const modalText = modalObjInfo.modalText || "";
      const btnArr = modalObjInfo.btnArr || [];
      this.modalInfo.showModal = !this.modalInfo.showModal;
      if (!this.modalInfo.showModal) {
        if (this.modalInfo.timer) clearInterval(this.modalInfo.timer);
        // 两秒后初始化vipId和initStep
        setTimeout(() => {
          this.changeInitStep(1);
          this.updateVipIdHandle("");
        }, 1000);
      } else {
        let count = 5;
        this.modalInfo.modalText = modalText + "，" + count + "秒后将关闭"; // '新增成功，5秒后将关闭'
        this.modalInfo.btnArr = btnArr; // ['关闭', '充值', '制卡']
        if (this.modalInfo.timer) clearInterval(this.modalInfo.timer);
        this.modalInfo.timer = setInterval(() => {
          count--;
          if (count <= 0) {
            clearInterval(this.modalInfo.timer);
            this.showOrHideModalHandle();
          }
          this.modalInfo.modalText = modalText + "，" + count + "秒后将关闭";
        }, 1000);
      }
    },
    // 判断是否为手机号格式
    isPhoneNumber(str) {
      // 检查是否全为数字且长度在4-11位之间（支持部分手机号搜索）
      return /^\d{4,11}$/.test(str);
    },
    
    remoteMethod(query) {
      if (query !== "") {
        this.remoteLoading = true;
        const result =
          this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
        this.personOptions = result.filter(
          (item) =>
            item.code.includes(query) ||
            item.name.includes(query) ||
            item.namePy.includes(query)
        );
        this.remoteLoading = false;
      } else {
        this.options = [];
      }
    },
  },
  created() {
    this.getTableData(true);
    this.changeInitStep(1);
    this.updateVipIdHandle("");
  },
  components: {
    IconButton,
    CharactersButton,
    drawerAddVip,
    drawerAddMoneyToVip,
    drawerReadCard,
    drawerPayNumSearch,
    drawerVipDetail,
    drawerOptionEvent,
    modalCom,
  },
  watch: {
    "form.typeVal"(newVal) {
      const currentTypeInfo =
        this.form.typeOption.find((item) => item.id == newVal) || {};
      this.form.deepOption = currentTypeInfo.ls || [];
    },
  },
  computed: {
    // 是否添加/修改会员权限
    hasAddOrEditAuth() {
      return (
        this.$store.getters.vipAuth ||
        (this.$store.state.userInfo.sys_modules &&
          this.$store.state.userInfo.sys_modules.includes(30))
      );
    },
  },
};
</script>

<style lang="less" scoped>
@import "../../style/vip/vip.less";
@import "../../style/vip/vipBtn.less";
@import "../../style/vip/vipManager.less";
@import "../../style/vip/vipPagination.less";
</style>

<style>
.el-select-dropdown__empty {
  background-color: #bec5d5 !important;
}

.el-scrollbar .el-scrollbar__view.el-select-dropdown__list {
  background-color: #bec5d5 !important;
}

.el-picker-panel {
  background-color: #bec5d5 !important;
}

/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}

.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}
</style>
<style scoped>
.el-select-dropdown__item {
  color: #1a1a21;
  font-size: 14px;
}

.el-select-dropdown__item.hover,
.el-select-dropdown__item:hover {
  background-color: rgba(90, 90, 90, 0.5) !important;
}
</style>
