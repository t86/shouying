<template>
  <div class="set-area-library">
    <el-dialog title="批量设置区域出品库" :visible.sync="show" :close-on-click-modal="false">
      <section>
        <header layout="row" layout-align="start center">
          <div :class="{'active': activeIndex == 1}" class="header-item" @click="activeIndex = 1">单品</div>
          <div :class="{'active': activeIndex == 2}" class="header-item" @click="activeIndex = 2">套餐</div>
        </header>
        <!-- 单品 -->
        <main v-if="activeIndex == 1">
          <p style="color:#D9001B;line-height: 50px">说明：勾选可点区域则必须配置出品库</p>
          <div class="contain">
            <div class="first-cate" v-for="item in singlePrdInfo.prdList" :key="item.id">
              <div class="name" @click.stop="item.showList = !item.showList">
                <i :class="[item.showList ? 'el-icon-minus' : 'el-icon-plus']" />
                <span>{{item.n}}</span>
              </div>
              <div class="p-l-5" v-if="item.showList">
                <div class="second-cate m-t-2" v-for="items in item.subs" :key="items.id">
                  <div class="name" @click.stop="getSingleDetailInfo(items)">
                    <i :class="[items.showList ? 'el-icon-minus' : 'el-icon-plus']" />
                    <span>{{items.n}}</span>
                    <div
                      v-if="items.showList"
                      class="button fr m-r-10"
                      @click.stop="saveSingleConfigHandle(items)"
                    >保存</div>
                  </div>
                  <div v-if="items.showList" class="second-detail p-l-5">
                    <!-- 通用配置 -->
                    <div>
                      <p class="m-t-4 m-b-4 bold">通用配置</p>
                      <div class="detail">
                        <div
                          style="line-height:30px"
                          v-if="!items.detailList || items.detailList.length == 0"
                        >暂无可配置项</div>
                        <div v-else layout="row" layout-align="start center">
                          <div class="detail-left" style="width: 200px">
                            <div
                              class="detail-left-item m-t-1 m-b-1"
                              style="line-height: 25px"
                              v-for="(itemInfo, index) in items.detailList"
                              :key="index"
                            >{{itemInfo.n}}</div>
                          </div>
                          <div class="detail-right" style="width:300px">
                            <div
                              class="detail-right-item m-t-1 m-b-1"
                              v-for="(itemInfo, index) in items.areaList"
                              :key="index"
                              layout="row"
                              layout-align="space-between center"
                            >
                              <el-checkbox
                                @change="$forceUpdate()"
                                v-model="itemInfo.checked"
                              >{{itemInfo.n}}</el-checkbox>
                              <el-select
                                @change="$forceUpdate()"
                                v-model="itemInfo.selectVal"
                                placeholder="请选择"
                              >
                                <el-option
                                  v-for="itemInfos in libraryOption"
                                  :key="itemInfos.id"
                                  :label="itemInfos.n"
                                  :value="itemInfos.id"
                                ></el-option>
                              </el-select>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <!-- 自定义商品出品库 -->
                    <div class="another">
                      <p class="m-t-4 m-b-4 bold">自定义商品出品库</p>
                      <div class="button m-b-4" @click.stop="addPrdToAnotherHandle(items)">添加</div>
                      <div class="detail">
                        <div
                          class="detail-item"
                          v-for="(itemInfo, index) in items.anotherPrdList"
                          :key="index"
                          layout="row"
                          layout-align="start center"
                        >
                          <div
                            class="detail-left m-t-1 m-b-1"
                            style="width: 200px;line-height: 25px"
                          >{{itemInfo.n}}</div>
                          <div class="detail-right" style="width:300px">
                            <div
                              class="detail-right-item m-t-1 m-b-1"
                              v-for="(itemInfos, i) in itemInfo.anotherAreaList"
                              :key="i"
                              layout="row"
                              layout-align="space-between center"
                            >
                              <el-checkbox
                                @change="$forceUpdate()"
                                v-model="itemInfos.checked"
                              >{{itemInfos.n}}</el-checkbox>
                              <el-select
                                @change="$forceUpdate()"
                                v-model="itemInfos.selectVal"
                                placeholder="请选择"
                              >
                                <el-option
                                  v-for="itemInfoss in libraryOption"
                                  :key="itemInfoss.id"
                                  :label="itemInfoss.n"
                                  :value="itemInfoss.id"
                                ></el-option>
                              </el-select>
                            </div>
                          </div>
                          <div
                            class="button m-l-10"
                            @click.stop="deleteAnotherConfigHandle(item,items,itemInfo)"
                          >删除</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </main>
        <!-- 套餐 -->
        <main v-else>
          <p style="color:#D9001B;line-height: 50px">说明：勾选可点区域</p>
          <div class="contain">
            <div class="first-cate" v-for="item in groupPrdInfo.prdList" :key="item.id">
              <div class="name" @click.stop="item.showList = !item.showList">
                <i :class="[item.showList ? 'el-icon-minus' : 'el-icon-plus']" />
                <span>{{item.n}}</span>
              </div>
              <div class="p-l-5" v-if="item.showList">
                <div class="second-cate m-t-2" v-for="items in item.subs" :key="items.id">
                  <div class="name" @click.stop="getGroupDetailInfo(items)">
                    <i :class="[items.showList ? 'el-icon-minus' : 'el-icon-plus']" />
                    <span>{{items.n}}</span>
                    <div
                      v-if="items.showList"
                      class="button fr m-r-10"
                      @click.stop="saveSingleConfigHandle(items)"
                    >保存</div>
                  </div>
                  <div v-if="items.showList" class="second-detail p-l-5">
                    <!-- 通用配置 -->
                    <div>
                      <p class="m-t-4 m-b-4 bold">通用配置</p>
                      <div class="detail">
                        <div
                          style="line-height:30px"
                          v-if="!items.detailList || items.detailList.length == 0"
                        >暂无可配置项</div>
                        <div v-else layout="row" layout-align="start center">
                          <div class="detail-left" style="width: 200px">
                            <div
                              class="detail-left-item m-t-1 m-b-1"
                              style="line-height: 25px"
                              v-for="(itemInfo, index) in items.detailList"
                              :key="index"
                            >{{itemInfo.n}}</div>
                          </div>
                          <div class="detail-right" style="width:300px">
                            <div
                              class="detail-right-item m-t-1 m-b-1"
                              v-for="(itemInfo, index) in items.areaList"
                              :key="index"
                            >
                              <el-checkbox
                                @change="$forceUpdate()"
                                v-model="itemInfo.checked"
                              >{{itemInfo.n}}</el-checkbox>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <!-- 自定义套餐可点区域 -->
                    <div class="another">
                      <p class="m-t-4 m-b-4 bold">自定义套餐可点区域</p>
                      <div class="button m-b-4" @click.stop="addPrdToAnotherHandle(items)">添加</div>
                      <div class="detail">
                        <div
                          class="detail-item"
                          v-for="(itemInfo, index) in items.anotherPrdList"
                          :key="index"
                          layout="row"
                          layout-align="start center"
                        >
                          <div
                            class="detail-left m-t-1 m-b-1"
                            style="width: 200px;line-height: 25px"
                          >{{itemInfo.n}}</div>
                          <div class="detail-right" style="width:300px">
                            <div
                              class="detail-right-item m-t-1 m-b-1"
                              v-for="(itemInfos, i) in itemInfo.anotherAreaList"
                              :key="i"
                            >
                              <el-checkbox
                                @change="$forceUpdate()"
                                v-model="itemInfos.checked"
                              >{{itemInfos.n}}</el-checkbox>
                            </div>
                          </div>
                          <div
                            class="button m-l-10"
                            @click.stop="deleteAnotherConfigHandle(item,items,itemInfo)"
                          >删除</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </main>
      </section>
      <span slot="footer" class="dialog-footer">
        <el-button type="primary" @click.native="closeDrawerHandle">取消</el-button>
      </span>
    </el-dialog>
    <choosePrd
      :showDrawer="showChoosePrdDrawer"
      :prdList="currentItemInfo.detailList"
      :activeIndex="activeIndex"
      @showOrHideChoosePrdDrawerHandle="showOrHideChoosePrdDrawerHandle"
      @addSingleListHandle="addSingleListHandle"
      @addGroupListHandle="addGroupListHandle"
    />
  </div>
</template>
 
<script>
import choosePrd from "./choosePrd.vue";
export default {
  data() {
    return {
      show: false,
      activeIndex: 1,
      singlePrdInfo: {
        prdList: []
      },
      groupPrdInfo: {
        prdList: []
      },

      // 出品库下拉框选项
      libraryOption: [],

      showChoosePrdDrawer: false,
      currentItemInfo: {
        detailList: []
      } // 添加自定义商品的当前二级菜单下所有信息
    };
  },
  methods: {
    // 获取一二级菜单
    async getOneAndTwoCate() {
      this.loading = this.$loading({
        lock: true,
        text: "Loading",
        spinner: "el-icon-loading",
        background: "rgba(0, 0, 0, 0.7)"
      });
      try {
        const res = await this.$api.BMS.Prd.requestprdcatetree();
        if (res.code == 1) {
          const cateList = res.data || [];
          cateList.forEach(el => {
            el.showList = false;
            el.subs = el.subs || [];
            el.subs.forEach(ele => {
              ele.showList = false;
            });
          });
          this.singlePrdInfo.prdList = JSON.parse(JSON.stringify(cateList));
          this.groupPrdInfo.prdList = JSON.parse(JSON.stringify(cateList));
        } else {
          this.$message.warning(res.msg);
        }
        this.loading.close();
      } catch (error) {
        this.loading.close();
        console.log("获取一二级菜单列表失败", error);
      }
    },

    // ================= 单品相关 start ====================

    // 单品获取二级菜单下单品相关信息
    async getSingleDetailInfo(itemInfo) {
      itemInfo.showList = !itemInfo.showList;

      // 收起二级分类
      if (!itemInfo.showList) return;

      const params = {
        id: itemInfo.id // int64  二级分类Id
      };
      this.loading = this.$loading({
        lock: true,
        text: "Loading",
        spinner: "el-icon-loading",
        background: "rgba(0, 0, 0, 0.7)"
      });
      try {
        const res = await this.$api.BMS.Prd.reqGetTwoCateSingleDetail(params);
        if (res.code == 1) {
          if (!res.data.prd_cfgs) {
            // 当前二级分类下无单品
            itemInfo.detailList = [];
          } else {
            // 通用配置
            res.data.prd_cfgs[0].ps = res.data.prd_cfgs[0].ps || [];
            itemInfo.detailList = JSON.parse(
              JSON.stringify(res.data.prd_cfgs[0].ps)
            );
            itemInfo.areaList = (res.data.region_dfns || []).map(item => ({
              ...item,
              checked: res.data.prd_cfgs[0].rs
                .map(items => items.r)
                .includes(item.id),
              selectVal: res.data.prd_cfgs[0].rs.find(
                items => items.r == item.id
              )
                ? res.data.prd_cfgs[0].rs.find(items => items.r == item.id).m
                : ""
            }));
            this.libraryOption = res.data.mklib_dfns || [];
            // 处理自定义配置
            const anotherPrdList = [];
            if (res.data.prd_cfgs.length > 1) {
              // 存在自定义配置
              res.data.prd_cfgs.forEach((el, index) => {
                // index == 0 时为通用配置
                if (index > 0) {
                  const anotherPrdListItem = {
                    n: el.ps[0].n,
                    id: el.ps[0].id
                  };
                  anotherPrdListItem.anotherAreaList = (
                    res.data.region_dfns || []
                  ).map(item => ({
                    ...item,
                    checked: el.rs.map(items => items.r).includes(item.id),
                    selectVal: el.rs.find(items => items.r == item.id)
                      ? el.rs.find(items => items.r == item.id).m
                      : ""
                  }));
                  anotherPrdList.push(anotherPrdListItem);
                }
              });
            }
            itemInfo.anotherPrdList = [...anotherPrdList];
            this.$forceUpdate();
          }
        } else {
          this.$message.warning(res.msg);
        }
        this.loading.close();
      } catch (error) {
        this.loading.close();
        console.log("二级菜单下单品详情获取失败", error);
      }
    },

    // 单品当前二级菜单添加自定义配置
    addSingleListHandle(prdList) {
      const selectedPrdIdList = prdList.map(item => item.id);
      prdList.forEach(el => {
        el.anotherAreaList = this.currentItemInfo.areaList.map(item => ({
          ...item,
          checked: false,
          selectVal: ""
        }));
      });
      const singlePrdList = [...this.singlePrdInfo.prdList];
      singlePrdList.forEach(el => {
        el.subs &&
          el.subs.forEach(ele => {
            if (ele.id == this.currentItemInfo.id) {
              ele.anotherPrdList = [...ele.anotherPrdList, ...prdList];
            }
            // 过滤已选择的商品
            if (ele.detailList && ele.detailList.length > 0) {
              const detailList = [];
              ele.detailList.forEach(element => {
                if (!selectedPrdIdList.includes(element.id)) {
                  detailList.push(element);
                }
              });
              ele.detailList = [...detailList];
            }
          });
      });
      this.singlePrdInfo.prdList = [...singlePrdList];
      this.showOrHideChoosePrdDrawerHandle();
    },

    // ================= 单品相关 end ====================

    // ================= 套餐相关 start ====================
    // 获取二级菜单下套餐列表信息
    async getGroupDetailInfo(itemInfo) {
      itemInfo.showList = !itemInfo.showList;

      // 收起二级分类
      if (!itemInfo.showList) return;

      const params = {
        id: itemInfo.id // int64  二级分类Id
      };
      this.loading = this.$loading({
        lock: true,
        text: "Loading",
        spinner: "el-icon-loading",
        background: "rgba(0, 0, 0, 0.7)"
      });
      try {
        const res = await this.$api.BMS.Prd.reqGetTwoCateGroupDetail(params);
        if (res.code == 1) {
          if (!res.data.set_cfgs) {
            // 当前二级分类下无套餐
            itemInfo.detailList = [];
          } else {
            // 通用配置
            res.data.set_cfgs[0].ps = res.data.set_cfgs[0].ps || [];
            itemInfo.detailList = JSON.parse(
              JSON.stringify(res.data.set_cfgs[0].ps)
            );
            itemInfo.areaList = (res.data.region_dfns || []).map(item => ({
              ...item,
              checked: res.data.set_cfgs[0].rs.includes(item.id)
            }));

            // 处理自定义配置
            const anotherPrdList = [];
            if (res.data.set_cfgs.length > 1) {
              // 存在自定义配置
              res.data.set_cfgs.forEach((el, index) => {
                // index == 0 时为通用配置
                if (index > 0) {
                  const anotherPrdListItem = {
                    n: el.ps[0].n,
                    id: el.ps[0].id
                  };
                  anotherPrdListItem.anotherAreaList = (
                    res.data.region_dfns || []
                  ).map(item => ({
                    ...item,
                    checked: el.rs.includes(item.id)
                  }));
                  anotherPrdList.push(anotherPrdListItem);
                }
              });
            }
            itemInfo.anotherPrdList = [...anotherPrdList];
            this.$forceUpdate();
          }
        } else {
          this.$message.warning(res.msg);
        }
        this.loading.close();
      } catch (error) {
        this.loading.close();
        console.log("二级菜单下套餐详情获取失败", error);
      }
    },

    // 当前二级菜单套餐添加自定义配置
    addGroupListHandle(prdList) {
      const selectedPrdIdList = prdList.map(item => item.id);
      prdList.forEach(el => {
        el.anotherAreaList = this.currentItemInfo.areaList.map(item => ({
          ...item,
          checked: false,
          selectVal: ""
        }));
      });
      const groupPrdList = [...this.groupPrdInfo.prdList];
      groupPrdList.forEach(el => {
        el.subs &&
          el.subs.forEach(ele => {
            if (ele.id == this.currentItemInfo.id) {
              ele.anotherPrdList = [...ele.anotherPrdList, ...prdList];
            }
            // 过滤已选择的商品
            if (ele.detailList && ele.detailList.length > 0) {
              const detailList = [];
              ele.detailList.forEach(element => {
                if (!selectedPrdIdList.includes(element.id)) {
                  detailList.push(element);
                }
              });
              ele.detailList = [...detailList];
            }
          });
      });
      this.groupPrdInfo.prdList = [...groupPrdList];
      this.showOrHideChoosePrdDrawerHandle();
    },

    // ================= 套餐相关 end ====================

    // 添加商品/套餐到自定义出品库
    addPrdToAnotherHandle(itemInfo) {
      this.currentItemInfo = JSON.parse(JSON.stringify(itemInfo));
      this.showOrHideChoosePrdDrawerHandle();
    },

    // 删除单品或套餐自定义商品配置
    deleteAnotherConfigHandle(item, items, itemInfo) {
      const prdList =
        this.activeIndex == 1
          ? [...this.singlePrdInfo.prdList]
          : [...this.groupPrdInfo.prdList];
      prdList.forEach(el => {
        if (el.id == item.id) {
          el.subs.forEach(ele => {
            if (ele.id == items.id) {
              ele.detailList.push(itemInfo);
              const index = ele.anotherPrdList.findIndex(
                element => element.id == itemInfo.id
              );
              if (index > -1) ele.anotherPrdList.splice(index, 1);
            }
          });
        }
      });
      this.activeIndex == 1
        ? (this.singlePrdInfo.prdList = [...prdList])
        : (this.groupPrdInfo.prdList = [...prdList]);
    },

    // 单品/套餐保存配置
    async saveSingleConfigHandle(itemInfo) {
      const prd_idxs = [];
      const prd_ids = [];
      const region_idxs = [];
      const regions = [];
      const mklibs = [];
      // 通用配置
      if (itemInfo.detailList.length > 0) {
        itemInfo.detailList.forEach(el => {
          prd_idxs.push(1);
          prd_ids.push(el.id * 1);
        });
        itemInfo.areaList
          .filter(item => item.checked)
          .forEach(el => {
            region_idxs.push(1);
            regions.push(el.id * 1);
            if(this.activeIndex == 1) mklibs.push(el.selectVal * 1);
          });
      }

      // 自定义配置
      itemInfo.anotherPrdList.forEach((el, index) => {
        prd_idxs.push(index + 2);
        prd_ids.push(el.id);
        el.anotherAreaList
          .filter(item => item.checked)
          .forEach(ele => {
            region_idxs.push(index + 2);
            regions.push(ele.id * 1);
            if(this.activeIndex == 1) mklibs.push(ele.selectVal * 1);
          });
      });

      const params = {
        prd_idxs, //   []int     商品配置编号, 从1开始编
        prd_ids, //    []int64   商品Id列表,和上面的商品配置编号是一对
        region_idxs, // []int     区域出品库配置编号, 从1开始编
        regions //    []int64   区域Id列表,和上面的区域出品库编号是一对
      };
      if (this.activeIndex == 1) {
        // 单品
        if (mklibs.includes(0))
          return this.$message.warning("选择的区域未配置出品库");

        params.mklibs = mklibs;
      }
      try {
        const apiName = this.activeIndex == 1 ? 'reqSaveSinglePrdConfig' : 'reqSaveGroupPrdConfig'
        const res = await this.$api.BMS.Prd[apiName](params);
        res.code == 1
          ? this.$message.success("保存成功")
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("保存配置失败", error);
      }
    },

    closeDrawerHandle() {
      this.$emit("showOrHideAreaLibraryHandle");
    },

    showOrHideChoosePrdDrawerHandle() {
      this.showChoosePrdDrawer = !this.showChoosePrdDrawer;
    }
  },
  created() {},
  mounted() {},
  props: {
    showDrawer: {
      type: Boolean,
      default: false
    }
  },
  components: {
    choosePrd
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) this.getOneAndTwoCate();
    }
  }
};
</script>

<style scoped lang="less">
.set-area-library {
  /deep/.el-dialog {
    width: 90vw;
    section {
      position: relative;
      header {
        position: sticky;
        top: 0;
        background-color: #f9f9f9;
        .header-item {
          padding: 10px 20px;
          font-size: 16px;
          border-bottom: 2px solid transparent;
          cursor: pointer;

          &.active {
            color: #2170ff;
            border-bottom-color: #2170ff;
          }
        }
      }
      main {
        .contain {
          border: 1px solid #d9d9d9;
          padding: 10px;
          box-sizing: border-box;
          .first-cate {
            .name {
              cursor: pointer;
              line-height: 30px;
            }

            .second-cate {
              .second-detail {
                border: 1px solid #d9d9d9;
                .detail {
                  padding: 10px;
                  background-color: #f5f5f5;
                  // height: 160px;
                  .detail-left,
                  .detail-right {
                    height: 100%;
                    overflow-y: auto;
                    overflow-x: hidden;
                  }
                }

                .another {
                  .detail {
                    padding: 0;
                    height: auto;
                    .detail-item {
                      padding: 10px;
                      box-sizing: border-box;
                      margin-bottom: 10px;
                      background-color: #f0f0f0;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

.button {
  display: inline-block;
  cursor: pointer;
  background-color: #2170ff;
  padding: 0px 10px;
  color: #fff;
  height: 26px;
  line-height: 26px;
  border-radius: 4px;
}

.bold{
  font-weight: 600;
}
</style>
<style>
.el-loading-mask.is-fullscreen {
  z-index: 9999 !important;
}
</style>