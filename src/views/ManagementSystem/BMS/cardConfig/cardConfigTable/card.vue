<template>
  <div class="one-table">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="addOrUpdateHandle(1)" text="新增" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="addOrUpdateHandle(2)" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(1)" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(2)" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
      <icon-button @click.native="setEffectOrNotEffect(3)" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
      <icon-button @click.native="showDrawerAddAllCard = true" text="批量新增" img="btn_batch_add.png" colors="#f5f5f5"></icon-button>
      <characters-button @click.native="showQrHandle" colors="#f5f5f5" wz='预览二维码'></characters-button>
      <characters-button @click.native="downloadExpQr" colors="#f5f5f5" wz='导出全部卡台二维码'></characters-button>
      <characters-button @click.native="$message.info('上下拖动区域可调整顺序')" colors="#383943" wz='调整顺序'></characters-button>
      <characters-button @click.native="configCanOrderPrd" colors="#383943" wz='功能台配置可点商品'></characters-button>
    </div>
    <div class="percentage" v-show="percentage">
      <span class="percentage_label">二维码生成进度：</span>
        <div class="percentage_value">
          <el-progress :percentage="percentage"></el-progress>
        </div>
    </div>
    <div class="table-content">
      <div class="table" ref="tableRef">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox
                v-model="checkAll"
                :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')"
              >全选</el-checkbox>
            </div>
            <div class="th">卡台名称</div>
            <div class="th">可坐人数</div>
            <div class="th">卡台类型</div>
            <div class="th">业务类型</div>
            <div class="th">创建时间</div>
            <div class="th">更新时间</div>
            <div class="th">状态</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked,'gray': item.s == '无效'}"
            layout="row"
            layout-align="space-between center"
            draggable="true"
            @dragstart="dragstart(item)"
            @dragenter="dragenter(item)"
            @dragend="dragend(item)"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td">
              <div style="width: 60px;text-align:left">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                >{{index + 1}}</el-checkbox>
              </div>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.cp}}</div>
            <div class="td">{{item.st}}</div>
            <div class="td">{{item.bt}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.s}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <!-- 新增或编辑 -->
        <drawerAddOrUpdateCard v-model="showDrawer" :menuList="menuList" :currentInfo="currentInfo" :type="type" @getTableData="getTableData" />
        <!-- 批量新增 -->
        <drawerAddAllCard v-model="showDrawerAddAllCard" :menuList="menuList" @getTableData="getTableData" />
        <!-- 预览二维码 -->
        <drawerShowQR v-model="showDrawerQr" :currentInfo="currentInfo" />
        <!-- 置为有效无效删除冲突 -->
        <drawerNextDrawer v-model="showNextDrawer" :effectType="effectType" :nexDrawerInfo="nexDrawerInfo"  @getTableData="getTableData" @setEffectOrNotEffect="setEffectOrNotEffect" />
        
        <!-- 添加商品 -->
        <drawerConfigOrderPrd v-model="showConfigPrdDrawer" :currentInfo="currentInfo" />

      </div>
    </div>
  </div>
</template>
 
<script>
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import drawerAddOrUpdateCard from './cardTableCom/drawerAddOrUpdateCard.vue'
import drawerAddAllCard from './cardTableCom/drawerAddAllCard.vue'
import drawerShowQR from './cardTableCom/drawerShowQr.vue'
import drawerNextDrawer from './cardTableCom/drawerNextDrawer.vue'
import drawerConfigOrderPrd from './cardTableCom/drawerConfigOrderPrd.vue'

import { projectName, projectConfig } from '@/utils/config/projectConfig.js'
import eventVue from "@/utils/eventVue";

export default {
  data() {
    return {
      tableData: [],
      checkAll: false,
      dragInfo: {}, // 拖拽信息
      type: 1, // 1:新增  2：修改
      effectType: 1, // 1无效  2有效 3删除
      currentInfo: {}, // 当前修改的数据
      showDrawer: false, 
      showDrawerAddAllCard: false, // 批量新增
      showDrawerQr: false, // 预览二维码
      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      nexDrawerInfo: {
        ns: [],
        cs: []
      },

      http: (process.env.NODE_ENV === 'development' ? projectConfig[projectName]['development'] : projectConfig[projectName]['product']) + '/exp',//路径

      jobId: '',
      percentage: 0,
      showConfigPrdDrawer: false,
      safeModeEnabled: false,
    };
  },
  methods: {
    getChoosedPrdList(){

    },
    async getTableData(isScrollToBottom = false) {
      const params = {
        id: this.$route.query.menuId * 1 || 0
      }
      try {
        const res = await this.$api.BMS.seat.requestseatlist(params);
        if (res.code == 1) {
          this.tableData = (res.data || [])
            .filter(item => !(this.safeModeEnabled && (item.bt === '关联功能台' || item.bt === '功能台')))
            .map(item => ({
              ...item,
              checked: false
            }));
          this.checkAll = false;
          this.$emit('getMenuList')
          if(isScrollToBottom) {
            this.$nextTick(() => {
              this.scrollBottom()
            })
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

    // 新增或修改
    addOrUpdateHandle(type) {
      const checkedList = this.tableData.filter(item => item.checked)
      if(type == 2) {
        if(checkedList.length == 1) {
          this.currentInfo = checkedList[0]
        } else {
          return this.$message.warning('请选择一条数据进行操作')
        }
      }
      this.showDrawer = true
      this.type = type
    },


    // 设为有效或无效或删除
    async setEffectOrNotEffect(type){
      // type : 1无效  2有效 3删除
      this.effectType = type
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length <= 0) return this.$message.warning('请选择一个进行操作')
      const params = {
        ids: checkedList.map(item => item.id * 1)
      }
      try {
        const api = type == 1 ? 'requestseatdisable' : (type == 2 ? 'requestseatenable' : 'requestseatdel')
        const res = await this.$api.BMS.seat[api](params)
        if(res.code == 1) {
          this.getTableData()
          this.$message.success('操作成功')
        } else if(res.code == 2) {
          this.showNextDrawer = true
          this.nexDrawerInfo.ns = res.data.ns || []
          this.nexDrawerInfo.cs = (res.data.cs || []).map(item => ({
            ...item,
            jg: '---'
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('设置有效无效失败', error);
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData = this.tableData.map(item => ({
            ...item,
            checked: this.checkAll
          }));
          break;
        case "item":
          this.checkAll = this.tableData.every(item => item.checked);
          break;
      }
    },

    showQrHandle(){
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length != 1) return this.$message.warning('请选择一个操作')
      this.currentInfo = checkedList[0]
      this.showDrawerQr = true
    },

    //导出全部卡台二维码
    async downloadExpQr(){
      try {
        const res = await this.$api.BMS.seat.requestSeatExpQr()
        if(res.code == 1) {
          this.jobId = res.data
          this.getExpQrPercent();
        }
      } catch (error) {
        console.log('导出二维码失败', error);
      }
    },

    configCanOrderPrd(){
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length == 1) {
        this.currentInfo = checkedList[0]
      } else {
        return this.$message.warning('请选择一条数据进行操作')
      }
      console.log(this.currentInfo);
      if(this.currentInfo.bt == '功能台' || this.currentInfo.bt == '关联功能台') {
        this.showConfigPrdDrawer = true
      } else {
        this.$message.warning('只有功能台和关联功能台支持配置商品')
      }

    },

    //获取文件下载进度
    async getExpQrPercent(){
      const params = {
        job_id: this.jobId
      }
      try {
        const res = await this.$api.BMS.seat.requestSeatGetExpQrPercent(params)
        if (res.code == 1) {
          if (res.data >= 100) {
            this.percentage = 100;
            let url = this.http + "/" + this.jobId;
            const a = document.createElement('a')//添加a标签
            document.body.appendChild(a);
            a.href = url
            a.setAttribute('download', this.jobId) // 下载文件的名称及文件类型后缀
            a.click()//点击标签
            document.body.removeChild(a); // 下载完成移除元素
            window.URL.revokeObjectURL(url); // 释放掉blob对象
          } else {
            this.percentage = +res.data;
            setTimeout(() => {
              this.getExpQrPercent();
            }, 1000)
          }
        }
      } catch (error) {
        console.log('获取下载文件进度失败', error);
      }
    },

    // 记录初始信息
    dragstart(item) {
      this.dragInfo.oldItem = item;
    },
    // 记录过程中信息
    dragenter(item) {
      this.dragInfo.newItem = item;
    },
    // 做最终操作
    async dragend(item) {
      if (this.dragInfo.oldItem != this.dragInfo.newItem) {
        let oldIndex = this.tableData.findIndex(items => items.id == this.dragInfo.oldItem.id);
        let newIndex = this.tableData.findIndex(items => items.id == this.dragInfo.newItem.id);
        const downUp = oldIndex > newIndex ? 2 : 1;

        const params = {
          id: this.dragInfo.oldItem.id,
          dest_id: this.dragInfo.newItem.id,
          down_up: downUp
        }

        try {
          const res = await this.$api.BMS.seat.requestSort(params)
          if(res.code == 1) {
            this.$message.success('更改位置成功')
            const newList = [...this.tableData]; // 中间数组，用于交换两个节点
            // 删除老的节点
            newList.splice(oldIndex, 1);
            //             // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.dragInfo.oldItem);
            //             // 更新this.List，触发transition-group的动画效果
            this.tableData = [...newList];
            this.$emit('getMenuList')
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('排序提交失败', error);
        }
      }
    },

    
    scrollBottom(){
      this.$nextTick(() => {
        const dom = this.$refs.tableRef
        dom && dom.scrollTo(0, 10000)
      })
    }
  },
  created() {
    this.getTableData();
  },
  mounted() {
    let safeMode = this.$store.state.cardPageInfo.resResultDataObj.safeMode || []
    this.safeModeEnabled = safeMode.some(item => item.id * 1 === 1 && item.param1 * 1 === 1)

    eventVue.$on("safeModeChanged", (e) => {
      console.log('safeModeChanged', e)
      this.safeModeEnabled = e[0][0] * 1 === 1 && e[0][1] * 1 === 1
      console.log('safeModeEnabled coming here', this.safeModeEnabled)
      this.getTableData()
    });
  },
  beforeDestroy() {
    eventVue.$off("safeModeChanged")
  },
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  },
  props: {
    menuList: {
      default: () => ([])
    }
  },
  components: {
    CharactersButton,
    IconButton,
    drawerAddOrUpdateCard,
    drawerAddAllCard,
    drawerShowQR,
    drawerNextDrawer,
    drawerConfigOrderPrd
  },
  watch: {
    '$route': {
      handler() {
        this.getTableData()
      }
    }
  }
};
</script>

<style lang="less" scoped>
@import "../../../../../style/erp/table.less";
</style>
<style scoped lang='less'>
.one-table {
  padding: 20px;
  height: 100%;
  position: relative;
  display: flex;
  flex-direction: column;

  .top {
    background-color: #eee;
    padding: 10px;
    position: sticky;
    top: 0;
    z-index: 10;
  }

  .percentage {
    padding: 0 10px;
    position: sticky;
    top: 60px;
    z-index: 10;
    background: #fff;
    width: 400px;
    display: flex;
    align-items: center;
    min-height: 50px;
    
    &_label {
      font-size: 12px;
      color: #40404e;
      display: inline-block;
    }

    &_value {
      display: inline-block;
      width: 300px;
    }
  }

  .table-content {
    flex: 1;
    overflow: auto;
    
    .table {
      .th,.td {
        &:nth-child(1),
        &:nth-child(3),
        &:nth-child(4),
        &:nth-child(5),
        &:nth-child(8){
          width: 40%;
        }
        &:nth-child(6),
        &:nth-child(7){
          width: 70%;
        }
      }
    }
  }
}
</style>