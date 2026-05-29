<template>
  <div>
    <!-- 商户号管理 -->
    <el-drawer
      title="商户号管理"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="merchant-tabs" v-if="hasMultipleMainEntities">
        <el-tabs v-model="activeTab">
          <el-tab-pane label="全局配置" name="global"></el-tab-pane>
          <el-tab-pane :label="getMainEntityLabel(0)" :name="'entity-' + mainEntities[0].id" v-if="mainEntities.length > 0"></el-tab-pane>
          <el-tab-pane :label="getMainEntityLabel(1)" :name="'entity-' + mainEntities[1].id" v-if="mainEntities.length > 1"></el-tab-pane>
        </el-tabs>
      </div>

      <div class="merchant fs14 merchant-online-collect-section" v-if="onlineCollectMerchants.length > 0">
        <div class="coll merchant-online-header" layout="row" layout-align="start center">
          <div class="label">
            <span>线上收款功能：</span>
          </div>
          <div class="value merchant-online-list">
            <div
              class="merchant-online-item"
              v-for="item in onlineCollectMerchants"
              :key="item.id"
            >
              <div class="merchant-online-item-text">{{ formatOnlineMerchantText(item) }}</div>
              <el-switch
                :value="item.onlineCollectEnabled"
                :loading="item.savingOpenClose"
                active-text="开"
                inactive-text="关"
                active-color="#409EFF"
                inactive-color="#ccc"
                @change="handleOnlineCollectToggle(item, $event)"
              />
            </div>
          </div>
        </div>
        <div class="line"></div>
      </div>

      <!-- 全局配置 -->
      <div class="merchant fs14" v-if="activeTab === 'global' && hasMultipleMainEntities">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span>默认主体：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <div 
              class="merchant-item" 
              :class="{'active': defaultEntityId == item.id}" 
              v-for="item in mainEntities" 
              :key="item.id" 
              @click="defaultEntityId = item.id"
            >
              {{item.n}}组
            </div>
          </div>
        </div>
        
        <div class="red-color fs12 m-l-10 p-l-10 m-t-2">未绑定客户号的区域，线上收款计入选择的默认主体</div>
        
        <div class="line"></div>
        
        <!-- 当前主体A -->
        <div v-for="(entity, index) in mainEntities" :key="entity.id" class="entity-section">
          <div class="coll current-entity" layout="row" layout-align="start center">
            <div class="label current-entity-label">
              <span class="entity-label">当前主体：</span>
            </div>
            <div class="value">
              <span class="entity-name">{{ entity.n }}组</span>
            </div>
          </div>
          
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>选择对S商户号：</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <div 
                v-for="item in getPrivateMerchants()" 
                :key="item.id"
                class="merchant-checkbox"
              >
                <el-checkbox 
                  v-model="entityMerchants[entity.id][item.id]" 
                  @change="handleEntityMerchantChange(entity.id, item.id)"
                >
                  {{item.n}}
                </el-checkbox>
              </div>
            </div>
          </div>
          
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>选择区域：</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <div 
                v-for="area in groupData.region_def" 
                :key="area.id"
                class="area-checkbox"
              >
                <el-checkbox 
                  v-model="entityRegions[entity.id][area.id]" 
                  @change="handleEntityRegionChange(entity.id, area.id)"
                >
                  {{area.n}}
                </el-checkbox>
              </div>
            </div>
          </div>
          
          <div class="red-color fs12 m-l-10 p-l-10 m-t-2">
            被别的主体选择过的区域，请先去取消选择，再进行勾选
          </div>
          
          <div class="line" v-if="index < mainEntities.length - 1"></div>
        </div>
      </div>

      <!-- 非全局配置 -->
      <div class="merchant fs14" v-if="activeTab !== 'global' || !hasMultipleMainEntities">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>自动切换商户号：</span>
          </div>
          <div class="value">
            <el-switch
                active-text="是"
                inactive-text="否"
              v-model="merchantVal"
              active-color="#409EFF"
              inactive-color="#ccc">
            </el-switch>
          </div>

          <!-- <el-button type="primary" @click="saveMerchantConfig">保存修改</el-button> -->
        </div>

        <div class="coll" layout="row" layout-align="start center" v-if="merchantVal">
          <div class="label">
            <span class="red-color">*</span>
            <span>设置公账金额阈值：</span>
          </div>
          <div class="value">
            <el-input
              style="width:180px"
              v-model="maxAmtVal"
              size="mini"
              placeholder="请输入金额"  
            >
            </el-input>&nbsp;元
          </div>
        </div>

        <div class="coll" layout="row" layout-align="start center" v-if="merchantVal">
          <div class="label">
            <span class="red-color">*</span>
            <span>选择商户号：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <div class="merchant-item" 
              :class="{
                'merchant-common': item.gs == 1, 
                'active': item.id == selectMerchantId
              }" 
              v-for="item in merchantList" 
              :key="item.id" 
              v-show="item.gs == 2" 
              @click="selectMerchantId = item.id"
            >{{item.n}}</div>
          </div>
        </div>

        <div v-if="merchantVal" class="red-color fs12 m-l-10 p-l-10 m-t-2">当门店已收公帐金额达到设置的公帐金额阈值后，会自动将门店所有卡台线上收款切换到选择的商户号；达不到则不切换；设置完成后即时生效！</div>

        <div class="line"></div>

        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span>默认商户号：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <div class="merchant-item" 
              :class="{
                'merchant-common': item.gs == 1, 
                'active': item.id == defaultMerchantId
              }" 
              v-for="item in merchantList" 
              :key="item.id" 
              @click="defaultMerchantId = item.id"
            >{{item.n}}</div>
          </div>
        </div>

        <!-- <div class="red-color fs12 m-l-10 p-l-10 m-t-2">未绑定商户号的卡台，线上收款计入选择的默认商户号</div> -->

        <div class="line"></div>
        
        <div class="coll" layout="row" layout-align="start start">
          <div class="label">
            <span class="red-color">*</span>
            <span>时段额度控制：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <div class="content-table" layout="row" layout-align="start start">
              <div class="table-content left-table">
                <div class="table">
                  <div class="thead">
                    <div class="tr" layout="row" layout-align="space-between center">
                      <div class="th">时间段(不含右区间)</div>
                      <div class="th">额度金额</div>
                      <div class="th">选择商户号</div>
                    </div>
                  </div>
                  <div class="tbody">
                    <div class="tr" v-for="(item, index) in leftTableData" :key="index" layout="row" layout-align="space-between center">
                      <div class="td">{{item.name}}</div>
                      <div class="td">
                        <el-input v-model="item.amt" placeholder="请输入金额" size="mini" @change="handleAmtChange(item)"></el-input>
                      </div>
                      <div class="td" layout="row" style="flex-wrap:wrap">
                        <div class="merchant-item" :class="{'active': item.checkedId == items.id}" v-show="items.gs == 2" v-for="items in merchantList" :key="items.id" @click="item.checkedId = items.id">{{items.n}}</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="table-content right-table">
                <div class="table">
                  <div class="thead">
                    <div class="tr" layout="row" layout-align="space-between center">
                      <div class="th">时间段(不含右区间)</div>
                      <div class="th">额度金额</div>
                      <div class="th">选择商户号</div>
                    </div>
                  </div>
                  <div class="tbody">
                    <div class="tr" v-for="(item, index) in rightTableData" :key="index" layout="row" layout-align="space-between center">
                      <div class="td">{{item.name}}</div>
                      <div class="td">
                        <el-input v-model="item.amt" placeholder="请输入金额" size="mini" @change="handleAmtChange(item)"></el-input>
                      </div>
                      <div class="td" layout="row" style="flex-wrap:wrap">
                        <div class="merchant-item" :class="{'active': item.checkedId == items.id}" v-show="items.gs == 2" v-for="items in merchantList" :key="items.id" @click="item.checkedId = items.id">{{items.n}}</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="line"></div>

         <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span>商户号：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <div class="merchant-item" 
              :class="{
                'merchant-common': item.gs == 1, 
                'active': item.id == currentMerchantInfo.id
              }" 
              v-for="item in merchantList" 
              :key="item.id" 
              @click="changeSeatMerchantHandle(item)"
            >{{item.n}}</div>
          </div>
        </div>

        <div class="red-color fs12 m-l-10 p-l-10 m-t-2">未绑定商户号的卡台，线上收款计入选择的默认商户号</div>

        <div class="area-content" v-if="merchantList.length > 0">
          <div class="area-list" v-for="item in areaList" :key="item.id">
            <h3 class="area-name m-t-3 m-b-3">
              <span class="m-r-3">{{item.n}}</span>
              <el-checkbox v-model="item.checked" :indeterminate="item.isIndeterminate" @change="changeCheckBoxHandle(item)">全选</el-checkbox>
            </h3>
            <div class="seat-list" layout="row" layout-align="start start">
              <div class="item cursor" 
                :class="{
                  'active': items.no && items.no === currentMerchantInfo.n,
                  'gray': items.no && items.no !== currentMerchantInfo.n
                }" 
                v-for="items in item.ss" 
                :key="items.id" 
                @click="chooseSeatMerchantHandle(items)"
              >
                <div class="item-name fs18">{{items.n}}</div>
                <div class="item-merchant fs14">{{items.no ? (items.no.length > 5 ? ('*****' + items.no.slice(-5)): items.no) : ''}}</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 主体特定配置 -->
      <div class="merchant fs14" v-if="activeTab.startsWith('entity-') && hasMultipleMainEntities">
        <div class="line"></div>
        <!-- 这里放置与全局配置相同的内容，但数据源针对当前选中的主体 -->
      </div>

      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" v-if="activeTab === 'global' && hasMultipleMainEntities" @click="saveGlobalConfig">保存修改</el-button>
        <el-button type="primary" v-else @click="saveMerchantConfig">保存修改</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import merchantOnlineCollect from "@/utils/merchantOnlineCollect";
let loaded = false // 数据是否加载完成
let updated = false  // 数据是否被修改
const leftTableData = [
    {
    id: 12,
    name: '12:00-13:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 13,
    name: '13:00-14:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 14,
    name: '14:00-15:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 15,
    name: '15:00-16:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 16,
    name: '16:00-17:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 17,
    name: '17:00-18:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 18,
    name: '18:00-19:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 19,
    name: '19:00-20:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 20,
    name: '20:00-21:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 21,
    name: '21:00-22:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 22,
    name: '22:00-23:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 23,
    name: '23:00-24:00',
    amt: '0',
    checkedId: ''
  }
]
const rightTableData = [
  {
    id: 0,
    name: '00:00-01:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 1,
    name: '01:00-02:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 2,
    name: '02:00-03:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 3,
    name: '03:00-04:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 4,
    name: '04:00-05:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 5,
    name: '05:00-06:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 6,
    name: '06:00-07:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 7,
    name: '07:00-08:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 8,
    name: '08:00-09:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 9,
    name: '09:00-10:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 10,
    name: '10:00-11:00',
    amt: '0',
    checkedId: ''
  },
  {
    id: 11,
    name: '11:00-12:00',
    amt: '0',
    checkedId: ''
  },
]
export default {
  data() {
    return {
      show: false,
      merchantVal: false,  // 自动切换商户号
      maxAmtVal: '',  // 公账金额阈值
      selectMerchantId: '', // 选择商户号id
      defaultMerchantId: '', // 默认商户号id
      leftTableData,
      rightTableData,
      merchantList: [], // 商户号列表
      areaList: [], // 区域卡台列表
      currentMerchantInfo: {}, // 选中的tab商户信息
      groupData: {
        cnl_cfg_grps: null,
        cnl_cfg_def: [],
        region_def: []
      }, // 商户组列表
      activeTab: 'global', // 当前激活的标签页
      mainEntities: [], // 存储主体商户号(g=1)
      defaultEntityId: '', // 默认主体ID
      entityMerchants: {}, // 每个主体对应的商户号 {entityId: {merchantId: true/false}}
      entityRegions: {}, // 每个主体对应的区域 {entityId: {regionId: true/false}}
      currentEntityConfig: {}, // 当前选中主体的配置信息
      onlineCollectMerchants: [],
      closedMerchantIds: [],
    };
  },
  computed: {
    hasMultipleMainEntities() {
      return this.mainEntities.length > 1;
    }
  },
  methods: {
    // 获取主体标签名称
    getMainEntityLabel(index) {
      if (this.mainEntities[index]) {
        return `主体(${this.mainEntities[index].n})组`;
      }
      return '';
    },
    
    // 获取当前选中主体的名称
    getCurrentEntityName() {
      const entityId = this.activeTab.replace('entity-', '');
      const entity = this.mainEntities.find(item => item.id == entityId);
      return entity ? entity.n : '';
    },

    formatOnlineMerchantText(item) {
      const merchantNo = item.n || '';
      const holderName = item.un || item.u || item.hn || '';
      const bankNo = item.bn || item.no || item.acct_no || '';
      return [merchantNo, holderName, bankNo].filter(Boolean).join(' -- ');
    },

    async handleOnlineCollectToggle(item, enabled) {
      const previous = item.onlineCollectEnabled;
      item.onlineCollectEnabled = enabled;
      item.savingOpenClose = true;

      try {
        const res = await api_money.save_cnl_cfg_openclose(
          merchantOnlineCollect.getOnlineCollectSaveParams(item.id, enabled)
        );

        if (res.code !== 1) {
          merchantOnlineCollect.rollbackOnlineCollectMerchant(item, previous);
          this.$message.warning(res.msg || '保存失败');
          return;
        }

        this.closedMerchantIds = merchantOnlineCollect.applyOnlineCollectSaveSuccess(
          this.closedMerchantIds,
          item.id,
          enabled
        );
        this.$message.success('设置成功');
      } catch (error) {
        merchantOnlineCollect.rollbackOnlineCollectMerchant(item, previous);
        this.$message.warning('保存失败，请稍后重试');
        console.log('保存商户号线上收款开关失败', error);
      } finally {
        item.savingOpenClose = false;
      }
    },

    async getDetailData(cnlCfgId = 0){
      try {
        const params = cnlCfgId ? { cnl_cfg_id: cnlCfgId } : {};
        const res = await api_money.reqGetMerchantConfig(params)
        if(res.code == 1) {
          console.log('接口返回数据:', res.data)
          
          // 初始化商户列表
          this.merchantList = res.data.cnl_cfgs || []
          console.log('初始化商户列表:', this.merchantList)
          
          // 设置商户号相关状态
          this.merchantVal = res.data.e_s == 1
          this.maxAmtVal = res.data.max_amt
          this.selectMerchantId = res.data.dest_cnl_cfg_id
          this.defaultMerchantId = res.data.def_cnl_cfg_id

          // 找到第一个不为0的c值对应的商户
          let firstNonZeroMerchant = null
          const regionSeats = res.data.region_seats || []
          console.log('区域座位数据:', regionSeats)
          
          for (const area of regionSeats) {
            console.log('当前区域:', area)
            if (area.ss && area.ss.length > 0) {
              console.log('当前区域的座位:', area.ss)
              const firstSeatWithC = area.ss.find(seat => seat.c)
              console.log('找到的第一个有c值的座位:', firstSeatWithC)
              if (firstSeatWithC && firstSeatWithC.c) {
                firstNonZeroMerchant = this.merchantList.find(m => m.id === firstSeatWithC.c)
                console.log('找到的对应商户:', firstNonZeroMerchant)
                break
              }
            }
          }

          // 设置当前选中的商户
          if (firstNonZeroMerchant) {
            console.log('设置currentMerchantInfo前:', this.currentMerchantInfo)
            this.currentMerchantInfo = {...firstNonZeroMerchant}
            console.log('设置currentMerchantInfo后:', this.currentMerchantInfo)
          } else {
            console.log('未找到符合条件的商户')
          }

          // 初始化区域座位数据
          this.areaList = regionSeats.map(item => {
            const seatList = (item.ss || []).map(items => {
              const merchantInfo = this.merchantList.find(m => m.id === items.c)
              return {
                ...items,
                no: merchantInfo ? merchantInfo.n : ''
              }
            })

            const allSelected = seatList.every(seat => seat.no === this.currentMerchantInfo.n)
            const someSelected = seatList.some(seat => seat.no === this.currentMerchantInfo.n)

            return {
              ...item,
              ss: seatList,
              checked: allSelected,
              isIndeterminate: !allSelected && someSelected
            }
          })
          console.log('初始化后的区域列表:', this.areaList)

          // 设置时段额度控制
          res.data.hour_cfgs = res.data.hour_cfgs || []
          this.rightTableData = this.rightTableData.map(item => {
            const find = res.data.hour_cfgs.find(items => items.h * 1 === item.id * 1) || {}
            return {
              ...item,
              amt: find.m || '0',
              checkedId: find.c || ''
            }
          })
          this.leftTableData = this.leftTableData.map(item => {
            const find = res.data.hour_cfgs.find(items => items.h * 1 === item.id * 1) || {}
            return {
              ...item,
              amt: find.m || '0',
              checkedId: find.c || ''
            }
          })
          
          updated = false
          setTimeout(() => {
            loaded = true
          }, 1000)

        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error)
      }
    },

    async getMerchantGroup(){
      const res = await api_money.get_cnl_cfg_grp()
      if(res.code == 1) {
        this.groupData = res.data
        this.closedMerchantIds = merchantOnlineCollect.getClosedMerchantIds(res.data)
        this.onlineCollectMerchants = merchantOnlineCollect.buildOnlineCollectMerchants(res.data)
        this.mainEntities = (res.data.cnl_cfg_def || []).filter(item => item.g == 1)
        
        if (this.mainEntities.length > 1) {
          this.activeTab = 'global';
          // 初始化默认主体
          if (!this.defaultEntityId && this.mainEntities.length > 0) {
            this.defaultEntityId = this.mainEntities[0].id;
          }
          
          // 初始化主体区域数据
          this.initEntityMerchants();
          this.initEntityRegions();
          
          // 根据接口返回数据初始化配置
          this.initConfigFromResponse(res.data);
        }
      }
    },

    // 改变商户tab
    changeSeatMerchantHandle(itemInfo){
      this.currentMerchantInfo = {...itemInfo}
      this.setCheckBoxStatus()
    },

    // 全选/反选区域
    changeCheckBoxHandle(itemInfo){
      itemInfo.isIndeterminate = false
      itemInfo.ss.forEach(el => {
        if(itemInfo.checked) {
          // 选中当前商户号
          el.no = this.currentMerchantInfo.n
        } else {
          el.no = ''
        }
      })
      this.setCheckBoxStatus()
    },

    // 卡台选中商户
    chooseSeatMerchantHandle(itemInfo) {
      console.log("itemInfo", itemInfo)
      console.log("this.currentMerchantInfo", this.currentMerchantInfo)
      if (!this.currentMerchantInfo || !this.currentMerchantInfo.n) {
        this.$message.warning('请先选择商户号')
        return
      }
      
      
      // 切换选中状态
      itemInfo.no = itemInfo.no === this.currentMerchantInfo.n ? '' : this.currentMerchantInfo.n
      
      // 更新全选和半选状态
      this.setCheckBoxStatus()
    },

    // 设置区域checkbox的全选半选
    setCheckBoxStatus() {
      this.areaList = this.areaList.map(item => {
        // 检查是否所有座位都选中了当前商户号
        const allSelected = item.ss.every(seat => seat.no === this.currentMerchantInfo.n)
        // 检查是否有座位选中了当前商户号
        const someSelected = item.ss.some(seat => seat.no === this.currentMerchantInfo.n)
        
        return {
          ...item,
          checked: allSelected,
          isIndeterminate: !allSelected && someSelected
        }
      })
    },

    // 保存非全局配置修改
    async saveMerchantConfig() {
      if (!loaded) {
        this.$message.warning('数据加载中，请稍后再试');
        return;
      }
      
      // 获取当前选中的主体ID
      let cnl_cfg_id = 0;
      if (this.activeTab.startsWith('entity-')) {
        cnl_cfg_id = parseInt(this.activeTab.replace('entity-', ''));
      }
      
      // 验证表单
      if (this.merchantVal && !this.maxAmtVal) {
        this.$message.warning('请输入公账金额阈值');
        return;
      }
      
      if (this.merchantVal && !this.selectMerchantId) {
        this.$message.warning('请选择商户号');
        return;
      }
      
      if (!this.defaultMerchantId) {
        this.$message.warning('请选择默认商户号');
        return;
      }
      
      // 准备请求参数
      const params = {
        cnl_cfg_id: cnl_cfg_id, // 主体商户号ID
        def_cnl_cfg_id: this.defaultMerchantId,
        enable_switch: this.merchantVal ? 1 : 2,
        max_amt: this.merchantVal ? parseInt(this.maxAmtVal) : 0,
        dest_cnl_cfg_id: this.merchantVal ? this.selectMerchantId : 0,
        seat_ids: [],
        seat_cnl_ids: [],
        hour_ids: [],
        hour_max_amts: [],
        hour_cnl_cfg_ids: []
      };
      
      // 收集卡台商户号配置
      this.areaList.forEach(area => {
        if (area.ss && area.ss.length > 0) {
          area.ss.forEach(seat => {
            if (seat.no) {
              // 找到对应的商户号ID
              const merchantInfo = this.merchantList.find(item => item.n.toString() === seat.no.toString());
              if (merchantInfo) {
                params.seat_ids.push(seat.id);
                params.seat_cnl_ids.push(merchantInfo.id);
              }
            }
          });
        }
      });
      
      // 收集时段配置
      this.leftTableData.forEach(item => {
        // if (item.amt !== '0' || item.checkedId) {
          params.hour_ids.push(item.id);
          params.hour_max_amts.push(parseInt(item.amt) || 0);
          params.hour_cnl_cfg_ids.push(item.checkedId || 0);
        // }
      });
      
      // 收集右侧时段配置
      this.rightTableData.forEach(item => {
        params.hour_ids.push(item.id);
        params.hour_max_amts.push(parseInt(item.amt) || 0);
        params.hour_cnl_cfg_ids.push(item.checkedId || 0);
      });
      
      console.log('保存商户号配置参数:', params);
      
      try {
        const res = await api_money.reqSaveMerchantConfig(params);
        if (res.code === 1) {
          this.$message.success('保存成功');
          // 重新加载数据
          if (this.activeTab.startsWith('entity-')) {
            this.loadEntityConfig(cnl_cfg_id);
          } else {
            // this.getMerchantList();
          }
        } else {
          this.$message.error(res.msg || '保存失败');
        }
      } catch (error) {
        console.error('保存商户号配置失败', error);
        this.$message.error('保存失败，请稍后重试');
      }
    },

    async onSubmit(){
      const seatIdIdList = []
      const seatMerchantIdList = []
      this.areaList.forEach(el => {
        el.ss && el.ss.forEach(ele => {
          if(ele.no.toString().length > 1) {
            const currentMerchantInfo = this.merchantList.find(item => item.n.toString() === ele.no.toString())
            if(currentMerchantInfo) {
              seatIdIdList.push(ele.id)
              seatMerchantIdList.push(currentMerchantInfo.id)
            }
          }
        })
      })
      const resultHoursList = [...this.rightTableData, ...this.leftTableData]
      console.log(resultHoursList);
      
      const params = {
        def_cnl_cfg_id: this.defaultMerchantId * 1, // int64    默认商户号Id
        enable_switch: this.merchantVal ? 1: 2, // int    阀值切换开关 1 开启 2 关闭
        max_amt: this.maxAmtVal * 1, //    int     阀值金额,单位元
        dest_cnl_cfg_id: this.selectMerchantId * 1, // int64    阀值切换目标商户号Id
        seat_ids: seatIdIdList, //   []int64   有配置商户号的卡台列表,没有配置不需要传
        seat_cnl_ids: seatMerchantIdList, // []int64   匹配上面卡台列表的商户号Id
        hour_ids: resultHoursList.map(item => item.id * 1), //   []int   时段标记数组(这里对应0~23), 定义 0 对应00:00-01:00   1 对应 01:00--02:00  以此类推
        hour_max_amts: resultHoursList.map(item => item.amt * 1), // []int   对应上面时段数组的,时段阀值金额,单位元
        hour_cnl_cfg_ids: resultHoursList.map(item => item.checkedId * 1), // []int64  对应上面时段数组的,指定对私商户号
      }

      if(params.enable_switch == 1) {
        if(!params.max_amt) return this.$message.warning('请输入默认公账金额阈值')
        if(!params.dest_cnl_cfg_id) return this.$message.warning('请输入选择商户号')
      }
      try {
        const res = await api_money.reqSaveMerchantConfig(params)
        if(res.code == 1) {
          this.$message.success('设置成功')
          this.$emit("showOrHideDrawer");  
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }

    },

    onCancelDrawer() {
      // if(updated) {
      //   this.$confirm('您已修改数据，尚未保存，需要保存后退出吗?', '提示', {
      //     confirmButtonText: '确定',
      //     cancelButtonText: '取消',
      //   }).then(() => {
      //     this.onSubmit()
      //   }).catch(() => {
      //     this.$emit("showOrHideDrawer");          
      //   });
      // } else {
      //   this.$emit("showOrHideDrawer");
      // }
      this.$emit("showOrHideDrawer");
    },

    // 初始化主体商户号数据
    initEntityMerchants() {
      this.mainEntities.forEach(entity => {
        if (!this.entityMerchants[entity.id]) {
          this.$set(this.entityMerchants, entity.id, {});
        }
        
        const privateMerchants = this.getPrivateMerchants();
        privateMerchants.forEach(merchant => {
          if (this.entityMerchants[entity.id][merchant.id] === undefined) {
            this.$set(this.entityMerchants[entity.id], merchant.id, false);
          }
        });
      });
    },
    
    // 处理主体商户号变更
    handleEntityMerchantChange(entityId, merchantId) {
      // 如果选中了某个商户号，需要在其他主体中取消选择该商户号
      if (this.entityMerchants[entityId][merchantId]) {
        for (const otherEntityId in this.entityMerchants) {
          if (otherEntityId != entityId) {
            this.$set(this.entityMerchants[otherEntityId], merchantId, false);
          }
        }
      }
    },
    
    // 根据接口返回数据初始化配置
    initConfigFromResponse(data) {
      if (!data || !data.cnl_cfg_grps) return;
      
      // 初始化默认主体
      const defaultEntity = data.cnl_cfg_grps.find(item => item.d === 1);
      if (defaultEntity) {
        this.defaultEntityId = defaultEntity.id;
      }
      
      // 初始化主体商户号和区域
      data.cnl_cfg_grps.forEach(grp => {
        // 初始化商户号
        if (grp.sids && grp.sids.length > 0) {
          if (!this.entityMerchants[grp.id]) {
            this.$set(this.entityMerchants, grp.id, {});
          }
          
          grp.sids.forEach(sid => {
            this.$set(this.entityMerchants[grp.id], sid, true);
          });
        }
        
        // 初始化区域
        if (grp.rs && grp.rs.length > 0) {
          if (!this.entityRegions[grp.id]) {
            this.$set(this.entityRegions, grp.id, {});
          }
          
          grp.rs.forEach(regionId => {
            this.$set(this.entityRegions[grp.id], regionId, true);
          });
        }
      });
    },

    // 获取对私商户号列表
    getPrivateMerchants() {
      if (!this.groupData || !this.groupData.cnl_cfg_def) {
        return [];
      }
      return this.groupData.cnl_cfg_def.filter(item => item.g === 2);
    },

    // 处理主体区域变更
    handleEntityRegionChange(entityId, regionId) {
      // 如果选中了某个区域，需要在其他主体中取消选择该区域
      if (this.entityRegions[entityId][regionId]) {
        for (const otherEntityId in this.entityRegions) {
          if (otherEntityId != entityId) {
            this.$set(this.entityRegions[otherEntityId], regionId, false);
          }
        }
      }
    },
    
    // 初始化主体区域数据
    initEntityRegions() {
      const regions = {};
      this.mainEntities.forEach(entity => {
        if (!this.entityRegions[entity.id]) {
          this.$set(this.entityRegions, entity.id, {});
        }
        
        this.groupData.region_def.forEach(region => {
          if (this.entityRegions[entity.id][region.id] === undefined) {
            this.$set(this.entityRegions[entity.id], region.id, false);
          }
        });
      });
    },

    // 保存全局配置
    async saveGlobalConfig() {
      if (!this.defaultEntityId) {
        this.$message.warning('请选择默认主体');
        return;
      }
      
      // 检查每个主体是否都选择了对S商户号
      for (const entity of this.mainEntities) {
        const selectedMerchants = Object.keys(this.entityMerchants[entity.id] || {})
          .filter(id => this.entityMerchants[entity.id][id]);
        
        if (selectedMerchants.length === 0) {
          this.$message.warning(`请为主体(${entity.n})组选择至少一个对S商户号`);
          return;
        }
      }
      
      // 检查每个主体是否都选择了区域
      for (const entity of this.mainEntities) {
        const selectedRegions = Object.keys(this.entityRegions[entity.id] || {})
          .filter(id => this.entityRegions[entity.id][id]);
        
        if (selectedRegions.length === 0) {
          this.$message.warning(`请为主体(${entity.n})组选择至少一个区域`);
          return;
        }
      }
      
      // 准备请求参数
      const params = {
        cnl_cfg_id1: this.mainEntities.length > 0 ? this.mainEntities[0].id : 0,
        cnl_cfg_id2: this.mainEntities.length > 1 ? this.mainEntities[1].id : 0,
        def_cnl_cfg_id: this.defaultEntityId,
        s_cfg_ids_1: [],
        s_cfg_ids_2: [],
        region_ids_1: [],
        region_ids_2: []
      };
      
      // 收集对S商户号ID
      if (this.mainEntities.length > 0) {
        for (const merchantId in this.entityMerchants[this.mainEntities[0].id]) {
          if (this.entityMerchants[this.mainEntities[0].id][merchantId]) {
            params.s_cfg_ids_1.push(parseInt(merchantId));
          }
        }
      }
      
      if (this.mainEntities.length > 1) {
        for (const merchantId in this.entityMerchants[this.mainEntities[1].id]) {
          if (this.entityMerchants[this.mainEntities[1].id][merchantId]) {
            params.s_cfg_ids_2.push(parseInt(merchantId));
          }
        }
      }
      
      // 收集区域ID
      if (this.mainEntities.length > 0) {
        for (const regionId in this.entityRegions[this.mainEntities[0].id]) {
          if (this.entityRegions[this.mainEntities[0].id][regionId]) {
            params.region_ids_1.push(parseInt(regionId));
          }
        }
      }
      
      if (this.mainEntities.length > 1) {
        for (const regionId in this.entityRegions[this.mainEntities[1].id]) {
          if (this.entityRegions[this.mainEntities[1].id][regionId]) {
            params.region_ids_2.push(parseInt(regionId));
          }
        }
      }
      
      console.log("save params:", params);
      try {
        const res = await api_money.save_cnl_cfg_grp(params);
        if (res.code === 1) {
          this.$message.success('保存成功');
          // 重新获取数据
          this.getMerchantGroup();
        } else {
          this.$message.error(res.msg || '保存失败');
        }
      } catch (error) {
        console.error('保存全局配置失败', error);
        this.$message.error('保存失败，请稍后重试');
      }
    },

    // 处理标签页切换
    handleTabChange(tab) {
      if (tab === 'global' && this.hasMultipleMainEntities) {
        // 切换到全局配置，清空当前配置数据
        this.resetConfigData();
      } else if (tab !== 'global' && this.hasMultipleMainEntities) {
        // 获取当前选中的主体ID
        const entityId = tab.replace('entity-', '');
        this.loadEntityConfig(entityId);
      }
    },
    
    // 重置配置数据
    resetConfigData() {
      this.merchantVal = false;
      this.maxAmtVal = '';
      this.selectMerchantId = '';
      this.defaultMerchantId = '';
      this.merchantList = [];
      this.areaList = [];
      this.currentMerchantInfo = {};
      // 重置时段数据为默认值
      this.leftTableData = this.leftTableData.map(item => ({
        ...item,
        amt: '0',
        checkedId: ''
      }));
      this.rightTableData = this.rightTableData.map(item => ({
        ...item,
        amt: '0',
        checkedId: ''
      }));
    },
    
    // 加载主体配置
    async loadEntityConfig(entityId) {
      try {
        const params = {
          cnl_cfg_id: parseInt(entityId)
        };
        
        const res = await api_money.reqGetMerchantConfig(params);
        console.log("loadEntityConfig返回数据:", res.data)
        if (res.code === 1) {
          this.currentEntityConfig = res.data;
          
          // 初始化表单数据
          this.merchantVal = res.data.e_s === 1; // 阀值切换标记
          this.maxAmtVal = res.data.max_amt.toString(); // 阀值金额
          this.selectMerchantId = res.data.dest_cnl_cfg_id; // 阀值切换目标商户号
          this.defaultMerchantId = res.data.def_cnl_cfg_id; // 默认商户号
          
          // 初始化商户号列表
          this.merchantList = res.data.cnl_cfgs || [];
          
          // 找到第一个不为0的c值对应的商户
          let firstNonZeroMerchant = null;
          const regionSeats = res.data.region_seats || [];
          console.log('区域座位数据:', regionSeats);
          
          for (const area of regionSeats) {
            if (area.ss && area.ss.length > 0) {
              const firstSeatWithC = area.ss.find(seat => seat.c);
              console.log('找到的第一个有c值的座位:', firstSeatWithC);
              if (firstSeatWithC && firstSeatWithC.c) {
                firstNonZeroMerchant = this.merchantList.find(m => m.id === firstSeatWithC.c);
                console.log('找到的对应商户:', firstNonZeroMerchant);
                break;
              }
            }
          }
          
          // 设置当前选中的商户
          if (firstNonZeroMerchant) {
            console.log('设置currentMerchantInfo前:', this.currentMerchantInfo);
            this.currentMerchantInfo = {...firstNonZeroMerchant};
            console.log('设置currentMerchantInfo后:', this.currentMerchantInfo);
          } else {
            console.log('未找到符合条件的商户');
          }
          
          // 初始化时段配置
          const allHourConfigs = this.initHourConfigs(res.data.hour_cfgs);
          
          // 分离左右表格数据：左边12-23小时，右边0-11小时
          this.leftTableData = allHourConfigs.filter(item => item.id >= 12 && item.id <= 23);
          this.rightTableData = allHourConfigs.filter(item => item.id >= 0 && item.id <= 11);
          
          // 初始化区域卡台配置
          this.areaList = regionSeats.map(item => {
            const seatList = (item.ss || []).map(items => {
              const merchantInfo = this.merchantList.find(m => m.id === items.c);
              return {
                ...items,
                no: merchantInfo ? merchantInfo.n : ''
              };
            });
            
            const allSelected = seatList.every(seat => seat.no === this.currentMerchantInfo.n);
            const someSelected = seatList.some(seat => seat.no === this.currentMerchantInfo.n);
            
            return {
              ...item,
              ss: seatList,
              checked: allSelected,
              isIndeterminate: !allSelected && someSelected
            };
          });
          console.log('初始化后的区域列表:', this.areaList);
          
          // 更新加载状态
          loaded = true;
        } else {
          this.$message.error(res.msg || '获取主体配置失败');
        }
      } catch (error) {
        console.error('加载主体配置失败', error);
        this.$message.error('加载主体配置失败，请稍后重试');
      }
    },
    
    // 初始化时段配置
    initHourConfigs(hourCfgs) {
      // 创建24小时的时段配置
      const hourData = [];
      for (let i = 0; i < 24; i++) {
        const nextHour = (i + 1) % 24;
        const hourItem = {
          id: i,
          name: `${i.toString().padStart(2, '0')}:00-${nextHour.toString().padStart(2, '0')}:00`,
          amt: '0',
          checkedId: ''
        };
        
        // 查找对应的配置
        const config = hourCfgs ? hourCfgs.find(cfg => cfg.h === i) : null;
        if (config) {
          hourItem.amt = config.m.toString();
          hourItem.checkedId = config.c;
        }
        
        hourData.push(hourItem);
      }
      
      return hourData;
    },

    // 在methods中添加打开商户号信息抽屉的方法
    getMerchantInfo(merchantId, amt, g_amt) {
      this.$emit('openMerchantInfoDrawer', {
        merchantId,
        amt,
        g_amt
      });
    },

    // 在methods中添加新方法
    handleAmtChange(item) {
      // 如果当前项没有选中的商户号，或者选中的商户号不是对私商户号，且商户列表不为空
      if ((!item.checkedId || !this.merchantList.find(m => m.id === item.checkedId && m.gs === 2)) && this.merchantList.length > 0) {
        // 找到第一个对私商户号（gs == 2）
        const firstPrivateMerchant = this.merchantList.find(m => m.gs === 2);
        if (firstPrivateMerchant) {
          item.checkedId = firstPrivateMerchant.id;
        }
      }
    },
  },
  created () {
    this.$watch(
      function () {
        return this.$data; // 监听整个 data 对象
      },
      function(){
        if(loaded){
          updated = true
        }
      },
      { deep: true }
    );
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.getMerchantGroup().then(() => {
          // 如果不是多主体模式，调用getDetailData
          if (!this.hasMultipleMainEntities) {
            this.getDetailData();
          }
          // 如果是多主体模式，但不在全局配置标签页，需要传递主体ID
          else if (this.activeTab !== 'global') {
            const entityId = this.activeTab.replace('entity-', '');
            this.getDetailData(parseInt(entityId));
          }
        });
      }
    },
    activeTab(newVal) {
      this.handleTabChange(newVal);
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";

.merchant-tabs {
  margin-bottom: 20px;
  padding: 0 20px;
  
  /deep/ .el-tabs__item {
    color: rgba(255, 255, 255, 0.7);
    font-size: 15px;
    padding: 0 20px;
    
    &.is-active {
      color: #409EFF;
      font-weight: bold;
    }
  }
  
  /deep/ .el-tabs__nav-wrap::after {
    background-color: rgba(255, 255, 255, 0.1);
  }
  
  /deep/ .el-tabs__active-bar {
    background-color: #409EFF;
    height: 3px;
  }
}

.entity-name {
  font-size: 18px;
  font-weight: 600;
  color: #409EFF;
  text-shadow: 0 0 5px rgba(64, 158, 255, 0.3);
}

.current-entity {
  background-color: rgba(64, 158, 255, 0.1);
  border-radius: 8px;
  padding: 10px;
  border-left: 4px solid #409EFF;
  
  .entity-label {
    font-size: 16px;
    font-weight: 500;
    color: #ffffff;
  }
}

.entity-section {
  margin-bottom: 20px;
}

.area-checkbox {
  margin: 5px 10px;
  
  /deep/ .el-checkbox__label {
    color: rgba(255, 255, 255, 0.8);
  }
}
</style>
<style lang="less" scoped>
.merchant{
  padding: 10px 20px 60px;
  box-sizing: border-box;
  color: rgba(255, 255, 255, 0.8);

  .coll {
    margin-top: 20px;
    .label {
      width: 160px;
      text-align: right;
    }
    .value {
      width: calc(100% - 160px);
      flex-wrap: wrap;
      margin-left: 10px;
      .merchant-item {
        min-width: 106px;
        position: relative;
        padding: 6px 10px;
        border: 1px solid #999;
        border-radius: 8px;
        cursor: pointer;
        margin: 4px 8px;

        &.merchant-common{
          &:after{
            position: absolute;
            content: '公';
            padding: 3px;
            border: 1px solid rgba(255, 255, 255, 0.8);
            background-color: #222f4d;
            border-radius: 50%;
            color: rgba(255, 255, 255, 0.8);
            font-size: 12px;
            right: 0;
            top: 0;
            transform: translate(50%, -50%);
          }
        }

        &.active{
          border-color: #409EFF;
          color: #409EFF;

          &.merchant-common{
            &:after{
              border-color: #409EFF;
              color: #409EFF;
            }
          }
        }

      }
    }
  }

  .line {
    width: 100%;
    height: 1px;
    background-color: rgba(255, 255, 255, 0.2);
    margin-top: 20px;
  }

  .area-content {
    padding-left: 40px;
    box-sizing: border-box;
    .seat-list {
      flex-wrap: wrap;
      .item {
        width: 110px;
        height: 60px;
        border: 1px solid #999;
        border-radius: 8px;
        margin: 10px;
        padding: 8px 10px;
        box-sizing: border-box;

        &.active {
          position: relative;
          background-color: #409EFF;
          border-color: #409EFF;
          &:after {
            position: absolute;
            right: 2px;
            top: 2px;
            padding: 2px;
            content: '√';
            border: 1px solid yellow;
            color: yellow;
            border-radius: 50%;
            transform: rotate(10deg);
          }
        }

        &.gray {
          background-color: #999;
        }


        .item-merchant {
          margin-top: 2px;
          text-align: right;
        }
      }
    }
  }
}

.merchant-online-collect-section {
  padding-bottom: 0;

  .merchant-online-header {
    align-items: flex-start;
  }

  .merchant-online-list {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .merchant-online-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    width: 100%;
    padding: 10px 0;
    border-bottom: 1px solid rgba(255, 255, 255, 0.12);

    &:last-child {
      border-bottom: 0;
    }
  }

  .merchant-online-item-text {
    flex: 1;
    line-height: 22px;
    word-break: break-all;
  }
}

/deep/.el-checkbox__label{
  color: rgba(255, 255, 255, 0.8);
}
</style>

<style lang="less" scoped>
.content-table {
  width: 100%;
  display: flex;
  flex-direction: row;
  gap: 10px;
  
  .table-content {
    flex: 1;
    min-width: 0;
    
    &.left-table {
      margin-right: 5px;
    }
    
    &.right-table {
      margin-left: 5px;
    }
  }
  
  .table {
    border: 1px solid #999;
    border-radius: 10px;
    width: 100%;
    overflow: hidden;

    .tr {
      box-sizing: border-box;
      min-height: 36px;
      // line-height: 36px;
      padding: 4px 0;
      font-size: 14px;
    }

    .thead {
      width: 100%;
      color: rgba(255, 255, 255, .5);
      position: sticky;
      top: 0;
      z-index: 1;
      background: #182037;
      // background: linear-gradient(180deg, #182037 0%, #11182D 100%);
      .th{
        background-color: #131b31;
      }
    }

    .tbody {
      width: 100%;
      .tr:nth-child(2n) {
        background-color: #2f3342;
        .td{
          background-color: #2f3342;
        }
      }
      .tr:nth-child(2n + 1) {
        background-color: #2A3959;
        .td{
          background-color: #2A3959;
        }
      }
    }

    .th,
    .td {
      flex: 1;
      padding: 0 10px;
      box-sizing: border-box;
      min-width: 0;
      
      &:first-child {
        min-width: 120px;
      }
      
      &:nth-child(2) {
        min-width: 120px;
      }
      
      &:last-child {
        min-width: 180px;
      }
    }
  }
}
</style>

<style lang="less" scoped>
.merchant-checkbox {
  margin: 5px 10px;
  
  /deep/ .el-checkbox__label {
    color: rgba(255, 255, 255, 0.8);
  }
}
</style>

<style lang="less" scoped>
.current-entity-label {
  text-align: left !important;
  padding-left: 15px;
}

.current-entity {
  background-color: rgba(64, 158, 255, 0.1);
  border-radius: 8px;
  padding: 10px;
  border-left: 4px solid #409EFF;
  
  .entity-label {
    font-size: 16px;
    font-weight: 500;
    color: #ffffff;
  }
}
</style>
