<template>
  <div>
    <!-- 查单权限 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <!-- 请选择角色 -->
        <div class="coll">
          <div class="label text-blue-500 p-4">请选择角色</div>
          <div class="value m-t-3 m-l-10">
            <el-checkbox
              v-for="item in erpList"
              :key="item.id"
              :indeterminate="item.st == 3"
              v-model="item.checked"
              class="m-b-2"
              @change="checkboxHandle(item)"
              >{{ item.n }}</el-checkbox
            >
          </div>
        </div>

        <div class="coll p-t-3" v-for="(items, index) in subList" :key="items.id">
          <div class="label">{{ items.t }}</div>
          <div
            layout="row"
            class="row value m-t-3 m-l-10"
            v-if="items.val.findIndex((i) => !i.row) >= 0 && !isSupervisorRole(items.t)"
          >
            <div class="m-t-2 m-b-2 m-l-2" v-for="item in items.val">
              <el-checkbox
                v-if="!item.row"
                v-model="item.checked"
                :disabled="item.disabled"
                :indeterminate="item.st == 3"
                @change="subCheckboxHandle(item)"
                >{{ item.n }}</el-checkbox
              >
              <p class="red-color fs12 m-t-2" v-if="item.m && !item.row">
                {{ item.m }}
              </p>
            </div>
          </div>
          <div
            layout="row"
            class="row value m-t-3 m-l-10"
            v-for="item in items.val.filter((i) => i.row && ![98, 99].includes(i.id))"
            v-if="!isSupervisorRole(items.t)"
          >
            <div class="m-t-2 m-b-2 m-l-2">
              <el-checkbox
                v-if="item.row"
                v-model="item.checked"
                :indeterminate="item.st == 3"
                :disabled="item.disabled"
                @change="subCheckboxHandle(item)"
                >{{ item.n }}</el-checkbox
              >
              <p class="red-color fs12 m-t-2" v-if="item.m && item.row">
                {{ item.m }}
              </p>
              
              <!-- 全场优惠权限的子权限选择 -->
              <div v-if="item.id === 12" class=" m-t-2 m-l-4">
                <div class="sub-permission-options">
                  <el-radio-group 
                    :value="getSelectedSubPermission(items.val)" 
                    @input="handleSubPermissionChange(items.val, $event)"
                    :disabled="!item.checked"
                  >
                    <el-radio 
                      v-for="subItem in items.val.filter(v => [98, 99].includes(v.id))"
                      :key="subItem.id"
                      :label="subItem.id"
                      :disabled="!item.checked"
                    >
                      {{ subItem.n }}
                    </el-radio>
                  </el-radio-group>
                </div>
              </div>

            </div>
          </div>

          <!-- 督查权限的子权限选择 - 只在第一个督查权限组显示 -->
          <div v-if="isSupervisorRole(items.t) && hasFullLookupPermission(items.val) && index === firstSupervisorGroupIndex" class=" m-t-2 m-l-4">
            <div class="supervisor-permission-options">
              <!-- 全场查单选项 -->
              <div class="full-lookup-section m-b-3">
                <el-checkbox
                  :value="isFullLookupSelectedGlobally()"
                  @input="handleFullLookupChangeGlobally($event)"
                  :disabled="!hasAnySupervisorPermissionGlobally()"
                >
                  全场查单
                </el-checkbox>
              </div>
              
              <!-- 区域选择 -->
              <div class="region-selection-section">
                <div class="region-title m-b-2">可查单区域 （请勾选可查单的区域）</div>
                <div class="region-checkboxes">
                  <el-checkbox
                    v-for="regionItem in getAllSupervisorRegions()"
                    :key="regionItem.id"
                    :value="regionItem.checked"
                    @input="handleRegionChangeGlobally(regionItem.id, $event)"
                    :disabled="!hasAnySupervisorPermissionGlobally() || isFullLookupSelectedGlobally()"
                    class="region-checkbox"
                  >
                    {{ regionItem.n }}
                  </el-checkbox>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
export default {
  data() {
    return {
      subList: [],
      erpList: [
        {
          id: 231590937409810,
          n: "咨客",
          st: 1,
        },
        {
          id: 231590939409812,
          n: "服务员",
          st: 2,
          subList: {
            t: "服务员权限",
            val: [
              {
                id: 23159093740981201,
                n: "存取酒操作权限",
                st: 201,
              },
              {
                id: 23159093740981202,
                n: "存酒超额权限",
                st: 202,
              },
              {
                id: 23159093740981203,
                n: "服务员退单",
                st: 203,
              },
              {
                id: 23159093740981211,
                n: "不允许查看下属点单消费",
                st: 211,
                row: true,
                w: "勾选后点单人只能查看自己点单的卡台消费，不能查看下属点单卡台的消费",
              },
            ],
          },
        },
        {
          id: 231590939409814,
          n: "营销",
          st: 3,
          subList: {
            t: "营销权限",
            val: [
              {
                id: 23159093940981401,
                n: "不允许查看下属点单消费",
                st: 301,
                row: true,
              },
              {
                id: 23159093940981402,
                n: "查看同组点单消费",
                st: 302,
                row: true,
                w: "勾选后点单人可查看同组人员点单卡台的消费",
              },
            ],
          },
        },
        {
          id: 231731521431462,
          n: "特饮",
          st: 4,
        },
      ],
    };
  },
  methods: {
    async getDetail() {
      const params = {
        station_ids: this.checkedList.map((item) => item.id),
      };
      try {
        const res = await this.$api.BMS.station.reGetSysRolesAndAuthModule(
          params
        );
        if (res.code == 1) {
          const role_module = res.data.sys_role_modules;
          const roles = res.data.sys_roles.map((d) => {
            const sub_module = role_module.filter((e) => e.r == d.n);
            if (sub_module.length > 0) {
              d.subList = {
                id: d.id,
                t: d.n + "权限",
                val: sub_module.map((m) => {
                  return {
                    ...m,
                    rId: d.id,
                    // row: m.m && m.m.length > 0,
                    row: true,
                    checked: m.st == 1,
                  };
                }),
              };
            }
            d.checked = d.st == 1;
            return d;
          });

          this.erpList = roles;

          const haveSub = this.erpList.filter((e) => (e.st == 1 || e.st == 3) && e.subList);
          this.subList = haveSub.map((e) => e.subList);
          console.log(this.subList)

          // 初始化子权限状态
          this.initializeSubPermissions();

          //set 83 disabled
          let hasSaveWine = 2
          for(let s of this.subList) {
            for (let v of s.val){
              if(v.id === 1){
                hasSaveWine = v.st
                break
              }
            }
          }

          for(let s of this.subList) {
            for (let v of s.val){
              if(v.id === 83){
                v.disabled = hasSaveWine  === 2
                break
              }
            }
          }

        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    async onSubmit() {
      const sel_roles = this.erpList.filter((e) => e.st == 1);
      const unchange_roles = this.erpList.filter((e) => e.st == 3);

      let modules = [];
      this.subList.forEach((e) => {
        modules = [...modules, ...e.val];
      });

      const sel_modules = modules.filter((e) => e.st == 1);
      const unchange_modules = modules.filter((e) => e.st == 3);

      const params = {
        station_ids: this.checkedList.map((item) => item.id * 1), // []int64  角色Id列表
        sel_sys_roles: sel_roles.map((e) => e.id * 1), // 全选中的系统角色列表
        unchange_sys_roles: unchange_roles.map((e) => e.id * 1), // 部分选中的系统角色列表(就是没有修改的部分选中的列表)
        sel_sys_modules: sel_modules.map((e) => e.id * 1), // 全选中的系统角色模块明细模块项
        unchange_sys_modules: unchange_modules.map((e) => e.id * 1), // 部分选中的系统角色模块项
      };

      try {
        const res = await this.$api.BMS.station.reSetSysRolesAuthModule(params);
        if (res.code == 1) {
          this.$message.success("设置成功");
          this.onCancelDrawer();
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("设置失败", error);
      }
    },

    onCancelDrawer() {
      this.show = false;
    },
    checkboxHandle(item) {
      if (item.st == 3) {
        this.erpList = this.erpList.map((e) => {
          if (e.id == item.id) {
            e.checked = true;
            e.st = 1;
          }
          return e;
        });
      } else {
        this.erpList = this.erpList.map((e) => {
          if (e.id == item.id) {
            e.st = e.checked ? 1 : 2;
          }
          return e;
        });
      }
      const haveSub = this.erpList.filter((e) => (e.st == 1 || e.st == 3) && e.subList);
      this.subList = haveSub.map((e) => e.subList);
    },
    subCheckboxHandle(item) {
      console.log('item:', item)
      if(item.id === 1){
        for(let s of this.subList) {
          for (let v of s.val){
            if(v.id === 83){
              if (item.checked){
                v.disabled = false
              } else {
                v.checked = false;
                v.disabled = true
              }
              break
            }
          }
        }
      }

      // 处理全场优惠权限
      if(item.id === 12){
        for(let s of this.subList) {
          for (let v of s.val){
            if([98, 99].includes(v.id)){
              if (item.checked){
                // 全场优惠权限被选中，启用子权限，默认选择98
                v.disabled = false;
                if(!v.checked && ![98, 99].some(id => s.val.find(sv => sv.id === id && sv.checked))){
                  // 如果没有任何子权限被选中，默认选择98
                  if(v.id === 98){
                    v.checked = true;
                    v.st = 1;
                  }
                }
              } else {
                // 全场优惠权限被取消，禁用并取消所有子权限
                v.checked = false;
                v.st = 2;
                v.disabled = true
              }
            }
          }
        }
      }

      // 处理督查角色选择
      const supervisorRoleItem = this.erpList.find(role => role.id === item.rId && this.isSupervisorRole(role.n));
      if(supervisorRoleItem) {
        // 如果督查角色被选中，初始化督查权限
        if(supervisorRoleItem.checked) {
          this.initializeSupervisorPermissions(supervisorRoleItem.subList);
        }
      }

      // rId
      const erpItem = this.erpList.find((e) => e.id == item.rId);

      if (erpItem.st == 3) {
        // 角色 st == 3 只能取消
        if (item.st != 3) {
          this.$message.warning("该角色权限未全部包含,只能取消权限");
        }
        this.subList = this.subList.map((e) => {
          if (e.id == item.rId) {
            e.val = e.val.map((m) => {
              if (m.id == item.id) {
                m.checked = false;
                m.st = 2;
              }
              return m;
            });
          }
          return e;
        });
      } else if (erpItem.st == 1) {
        this.subList = this.subList.map((e) => {
          if (e.id == item.rId) {
            e.val = e.val.map((m) => {
              if (m.id == item.id) {
                m.st = m.checked ? 1 : 2;
              }
              return m;
            });
          }
          return e;
        });
      } else if (erpItem.st == 2) {
        if (item.checked && item.st == 2) {
          this.$message.warning("该角色权限未选,不能选中");
        }
        // 未选角色不能编辑 取消选中
        this.subList = this.subList.map((e) => {
          if (e.id == item.rId) {
            e.val = e.val.map((m) => {
              if (m.id == item.id) {
                m.checked = false;
                m.st = 2;
              }
              return m;
            });
          }
          return e;
        });
      }
    },

    // 获取当前选中的子权限
    getSelectedSubPermission(permissions) {
      const subPermission = permissions.find(p => [98, 99].includes(p.id) && p.checked);
      return subPermission ? subPermission.id : null;
    },

    // 处理子权限选择变化
    handleSubPermissionChange(permissions, selectedId) {
      permissions.forEach(p => {
        if([98, 99].includes(p.id)){
          if(p.id === selectedId){
            p.checked = true;
            p.st = 1;
          } else {
            p.checked = false;
            p.st = 2;
          }
        }
      });
    },

    // 初始化子权限状态
    initializeSubPermissions() {
      for(let s of this.subList) {
        // 处理全场优惠权限
        const fullDiscountPermission = s.val.find(v => v.id === 12);
        const subPermissions = s.val.filter(v => [98, 99].includes(v.id));
        
        if(fullDiscountPermission && subPermissions.length > 0) {
          // 如果全场优惠权限未选中，禁用子权限
          if(!fullDiscountPermission.checked) {
            subPermissions.forEach(sp => {
              sp.disabled = true;
              sp.checked = false;
              sp.st = 2;
            });
          } else {
            // 如果全场优惠权限选中，启用子权限
            subPermissions.forEach(sp => {
              sp.disabled = false;
            });
            
            // 确保至少有一个子权限被选中，如果都没选中则默认选择98
            const hasSelectedSub = subPermissions.some(sp => sp.checked);
            if(!hasSelectedSub) {
              const defaultSub = subPermissions.find(sp => sp.id === 98);
              if(defaultSub) {
                defaultSub.checked = true;
                defaultSub.st = 1;
              }
            }
          }
        }

        // 处理督查权限
        this.initializeSupervisorPermissions(s);
      }
    },

    // 初始化督查权限状态
    initializeSupervisorPermissions(subListItem) {
      if(!this.isSupervisorRole(subListItem.t)) return;
      
      const fullLookupPermissions = subListItem.val.filter(v => [0].includes(v.id));
      const regionPermissions = subListItem.val.filter(v => ![0].includes(v.id));
      
      // 如果是老数据且没有任何权限被选中，默认选择全场查单
      const hasAnySelected = subListItem.val.some(v => v.checked);
      if(!hasAnySelected && fullLookupPermissions.length > 0) {
        // 默认选择全场查单（选择id=0）
        const defaultFullLookup = fullLookupPermissions.find(v => v.id === 0) || fullLookupPermissions[0];
        if(defaultFullLookup) {
          defaultFullLookup.checked = true;
          defaultFullLookup.st = 1;
        }
      }
    },

    // 判断是否为督查角色
    isSupervisorRole(roleTitle) {
      return roleTitle && roleTitle.includes('督查');
    },

    // 判断是否有全场查单权限
    hasFullLookupPermission(permissions) {
      return permissions.some(p => [0].includes(p.id));
    },

    // 判断是否有任何督查权限
    hasAnySupervisorPermission(permissions) {
      const supervisorRole = this.erpList.find(role => 
        role.subList && role.subList.val === permissions && this.isSupervisorRole(role.n + '权限')
      );
      return supervisorRole && supervisorRole.checked;
    },


    // 判断是否是区域权限
    isRegionPermission(permission) {
      // 区域权限的ID通常比较大，且不是0
      return permission.id && ![0, 98, 99].includes(permission.id) && permission.id > 1000;
    },

    // 判断是否选择了全场查单
    isFullLookupSelected(permissions) {
      return permissions.some(p => [0].includes(p.id) && p.checked);
    },

    // 获取督查区域权限
    getSupervisorRegions(permissions) {
      return permissions.filter(p => ![0].includes(p.id));
    },

    // 处理全场查单变化
    handleFullLookupChange(permissions, isChecked) {
      const fullLookupPermissions = permissions.filter(p => [0].includes(p.id));
      const regionPermissions = permissions.filter(p => ![0].includes(p.id));

      if(isChecked) {
        // 选择全场查单，取消所有区域选择
        regionPermissions.forEach(p => {
          p.checked = false;
          p.st = 2;
        });
        
        // 选择全场查单（优先选择id=0）
        const primaryFullLookup = fullLookupPermissions.find(p => p.id === 0) || fullLookupPermissions[0];
        if(primaryFullLookup) {
          primaryFullLookup.checked = true;
          primaryFullLookup.st = 1;
        }
        
        // 取消其他全场查单权限
        fullLookupPermissions.forEach(p => {
          if(p !== primaryFullLookup) {
            p.checked = false;
            p.st = 2;
          }
        });
      } else {
        // 取消全场查单
        fullLookupPermissions.forEach(p => {
          p.checked = false;
          p.st = 2;
        });
      }
    },

    // 处理区域权限变化
    handleRegionChange(permissions, regionId, isChecked) {
      const regionPermission = permissions.find(p => p.id === regionId);
      const fullLookupPermissions = permissions.filter(p => [0].includes(p.id));

      if(regionPermission) {
        regionPermission.checked = isChecked;
        regionPermission.st = isChecked ? 1 : 2;
      }

      // 如果选择了任何区域，取消全场查单
      if(isChecked) {
        fullLookupPermissions.forEach(p => {
          p.checked = false;
          p.st = 2;
        });
      }
    },

    // 全局督查权限方法 - 处理所有督查权限组
    getAllSupervisorGroups() {
      return this.subList.filter(group => 
        this.isSupervisorRole(group.t) && this.hasFullLookupPermission(group.val)
      );
    },

    // 判断是否有任何督查权限（全局）
    hasAnySupervisorPermissionGlobally() {
      return this.getAllSupervisorGroups().some(group => {
        const supervisorRole = this.erpList.find(role => 
          role.subList && role.subList.val === group.val && this.isSupervisorRole(role.n + '权限')
        );
        return supervisorRole && supervisorRole.checked;
      });
    },

    // 判断是否选择了全场查单（全局）
    isFullLookupSelectedGlobally() {
      return this.getAllSupervisorGroups().some(group =>
        group.val.some(p => [0].includes(p.id) && p.checked)
      );
    },

    // 获取所有督查区域权限（全局）
    getAllSupervisorRegions() {
      const allRegions = [];
      const regionMap = new Map();
      
      this.getAllSupervisorGroups().forEach(group => {
        group.val.filter(p => ![0].includes(p.id)).forEach(region => {
          if(!regionMap.has(region.id)) {
            regionMap.set(region.id, region);
            allRegions.push(region);
          }
        });
      });
      
      return allRegions.sort((a, b) => a.id - b.id);
    },

    // 处理全场查单变化（全局）
    handleFullLookupChangeGlobally(isChecked) {
      this.getAllSupervisorGroups().forEach(group => {
        this.handleFullLookupChange(group.val, isChecked);
      });
    },

    // 处理区域权限变化（全局）
    handleRegionChangeGlobally(regionId, isChecked) {
      this.getAllSupervisorGroups().forEach(group => {
        this.handleRegionChange(group.val, regionId, isChecked);
      });
    },
  },
  mounted() {},
  props: {
    value: {
      default: false, // 是否显示drawer
    },
    checkedList: {
      default: () => [],
    },
  },
  computed: {
    title() {
      return "角色权限";
    },

    // 获取第一个督查权限组的索引
    firstSupervisorGroupIndex() {
      return this.subList.findIndex(group => 
        this.isSupervisorRole(group.t) && this.hasFullLookupPermission(group.val)
      );
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      },
    },
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.getDetail();
        } else {
          this.areaList = [];
        }
      },
      immediate: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../../style/common/elementDrawerWine.less";
@import "../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../style/erp/form.less";
@import "../../../../../style/erp/table.less";

// @tailwind base;
// @tailwind components;
// @tailwind utilities;
</style>

<style lang="less" scoped>
.coll {
  .label {
    width: 100%;
    text-align: left;
  }
  .value {
    flex-wrap: wrap;
  }
}

.sub-permission-container {
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  padding: 15px;
  background-color: #fafbfc;
  margin-top: 8px;
  max-width: 95%;
  
  @media (orientation: portrait) {
    width: 95% !important;
    padding: 12px;
  }
  
  .sub-permission-title {
    font-weight: 500;
    color: #606266;
    margin-bottom: 8px;
  }
  
  .sub-permission-options {
    .el-radio-group {
      display: flex;
      flex-direction: column;
      
      @media (max-width: 900px) {
        flex-direction: column;
      }
      
      .el-radio {
        margin-right: 20px;
        margin-bottom: 8px;
        height: 38px;
        line-height: 38px;
        
        .el-radio__label {
          font-size: 14px;
          color: #606266;
        }
        
        &.is-disabled {
          .el-radio__label {
            color: #c0c4cc;
          }
        }
      }
    }
  }
}

// 督查权限容器样式
.supervisor-permission-container {
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  padding: 15px;
  background-color: #f8faff;
  margin-top: 8px;
  max-width: 95%;
  
  @media (orientation: portrait) {
    width: 95% !important;
    padding: 12px;
  }
  
  @media (max-width: 900px) {
    width: 95% !important;
    padding: 12px;
  }
  
  .supervisor-permission-title {
    font-weight: 500;
    color: #409eff;
    margin-bottom: 15px;
    font-size: 14px;
  }
  
  .supervisor-permission-options {
    .full-lookup-section {
      border-bottom: 1px solid #ebeef5;
      padding-bottom: 15px;
      
      .el-checkbox {
        height: 38px;
        line-height: 38px;
        
        .el-checkbox__label {
          font-size: 14px;
          font-weight: 500;
          color: #409eff;
        }
        
        &.is-disabled {
          .el-checkbox__label {
            color: #c0c4cc;
          }
        }
      }
    }
    
    .region-selection-section {
      padding-top: 15px;
      
      .region-title {
        font-size: 13px;
        color: #606266;
        font-weight: 500;
        margin-bottom: 8px;
      }
      
      .region-checkboxes {
        display: flex;
        flex-wrap: wrap;
        gap: 15px;
        
        @media (orientation: portrait) {
          flex-direction: column;
          gap: 8px;
        }
        
        @media (max-width: 900px) {
          flex-direction: column;
          gap: 8px;
        }
        
        .region-checkbox {
          height: 38px;
          line-height: 38px;
          min-width: 80px;
          
          .el-checkbox__label {
            font-size: 13px;
            color: #606266;
          }
          
          &.is-disabled {
            .el-checkbox__label {
              color: #c0c4cc;
            }
          }
        }
      }
    }
  }
}
</style>
