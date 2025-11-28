<template>
  <div>
    <!-- 新增或修改套餐 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="90%"
    >
      <div class="session p-5 fs14">
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>分类：</span>
          </div>
          <div class="value">
            <span>{{ oneCateInfo.n }}</span>
            <span> > </span>
            <span>{{ twoCateInfo.n }}</span>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red-color">*</span>
            <span>名称：</span>
          </div>
          <div class="value">
            <el-input
              v-model="name"
              size="mini"
              @change="validator('name')"
              placeholder="请输入名称"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>套餐类型：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <el-select
              v-model="setType"
              placeholder="请选择套餐类型"
              size="mini"
            >
              <el-option label="普通套餐" :value="2"></el-option>
              <el-option label="抖音套餐" :value="12"></el-option>
              <el-option label="美团套餐" :value="22"></el-option>
              <el-option label="推广套餐" :value="32"></el-option>
            </el-select>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>拼音简写：</span>
          </div>
          <div class="value">{{ py }}</div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>英文名：</span>
          </div>
          <div class="value">
            <el-input
              v-model="englishName"
              size="mini"
              @change="validator('englishName')"
              placeholder="请输入英文名称"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>单价：</span>
          </div>
          <div class="value">
            <el-input
              v-model="price"
              size="mini"
              placeholder="请输入单价"
            ></el-input>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>营业类型：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <el-select
              v-model="businessType"
              placeholder="请选择营业类型"
              size="mini"
            >
              <el-option label="主营" :value="1"></el-option>
              <el-option label="非主营" :value="2"></el-option>
              <el-option label="继承单品配置" :value="3"></el-option>
            </el-select>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>用途限制：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <el-checkbox v-model="userYH">仅用于优惠</el-checkbox>
          </div>
        </div>
        <div class="red-color fs12 m-b-2" style="margin-left: 122px">
          勾选后，该商品服务员点单和客人点单不可见，仅用于优惠
        </div>

        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>商品图片：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <div v-show="!picUrl" style="margin-left: 10px">
              <el-upload
                :key="show"
                action
                :show-file-list="false"
                :limit="1"
                accept=".jpg, .png"
                :with-credentials="true"
                ref="uploadPicUrlP"
                :http-request="uploadRequest"
              >
                <div class="upload-btn">
                  <div class="upload-btn-icon">
                    <img
                      style="height: 30px; width: 30px"
                      :src="require('@/assets/img/btn_add.png')"
                    />
                  </div>
                  <div class="upload-btn-text" style="color: #1a1a21">上传</div>
                </div>
              </el-upload>
              <div class="red-color fs12 m-t-2">
                点击上传图片，仅支持：jpg、png的格式
              </div>
            </div>
            <div v-show="picUrl" layout="column">
              <div class="prd-img" layout="row" layout-align="center center">
                <img v-if="picUrl" :src="`${http}${picUrl}`" />
              </div>
              <div
                class="prd-img-btn m-t-2"
                layout="row"
                layout-align="space-between center"
              >
                <div class="primary-link cursor" @click="showPreImage">
                  查看
                </div>
                <div class="primary-link cursor" @click="deleteImgHandle">
                  删除
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="coll" layout="row" layout-align="start center">
          <div class="label">
            <span>不可见端：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <el-checkbox v-model="limitPc">PC端</el-checkbox>
            <el-checkbox v-model="limitPad">PAD端</el-checkbox>
            <el-checkbox v-model="limitXcxEmp">小程序-员工端</el-checkbox>
            <el-checkbox v-model="limitXcxCust">小程序-客人端</el-checkbox>
          </div>
        </div>

        <div class="coll">
          <div class="label">
            <span>固定单品：</span>
          </div>
          <div class="value">
            <div class="table-content table1 m-t-3">
              <div class="table">
                <div class="thead">
                  <div
                    class="tr"
                    layout="row"
                    layout-align="space-between center"
                  >
                    <div class="th">行号</div>
                    <div class="th">单品名称</div>
                    <div class="th">分类</div>
                    <div class="th">单价</div>
                    <div class="th">
                      <span>数量</span>
                      <el-tooltip
                        class="item"
                        effect="light"
                        content="数量不填，默认为1"
                        placement="top"
                      >
                        <img
                          style="width: 14px; transform: translateY(-6px)"
                          :src="require('@/assets/img/btn_help.png')"
                          alt
                        />
                      </el-tooltip>
                    </div>
                    <div class="th">存商品名</div>
                    <div class="th">类型</div>
                    <div class="th">营业类型</div>
                    <div class="th">状态</div>
                    <div class="th">操作</div>
                  </div>
                </div>
                <div class="tbody">
                  <div
                    class="tr"
                    layout="row"
                    layout-align="space-between center"
                    v-for="(item, index) in fixedPrdTableData"
                    :key="item.id"
                  >
                    <div class="td">{{ index + 1 }}</div>
                    <div class="td">{{ item.n }}</div>
                    <div class="td">{{ item.on }} > {{ item.tn }}</div>
                    <div class="td">{{ item.p }}</div>
                    <div class="td">
                      <el-input
                        v-model="item.pc"
                        placeholder="请输入数量"
                        size="mini"
                      />
                    </div>
                    <div class="td">{{ item.mn }}</div>
                    <div class="td">{{ item.pt }}</div>
                    <div class="td">{{ item.bt }}</div>
                    <div class="td">{{ item.s == 1 ? "有效" : "无效" }}</div>
                    <div class="td">
                      <span
                        class="primary-link cursor"
                        @click="deletePrdHandle('fixedPrd', {}, item)"
                        >删除</span
                      >
                    </div>
                  </div>
                  <div class="no-data" v-if="fixedPrdTableData.length == 0">
                    <img
                      style="margin-top: 20px"
                      :src="require('@/assets/img/wu.png')"
                      alt
                    />
                    <p>暂无数据</p>
                  </div>
                </div>
              </div>
              <div class="add" layout="row" layout-align="center center">
                <span class="cursor primary-link fs20">+</span>
                <span
                  class="cursor primary-link fs14"
                  @click="addPrdHandle('fixedPrd')"
                  >添加单品</span
                >
              </div>
            </div>
          </div>
        </div>

        <div class="coll">
          <div class="label m-b-3">
            <span>可替换：</span>
          </div>
          <div class="value">
            <div
              class="table-content table2 m-b-6"
              v-for="items in canChoosePrdTableData"
              :key="items.id"
            >
              <div
                class="choose m-b-3 fs18"
                layout="row"
                layout-align="space-between center"
              >
                <div>
                  <div class="mb-4">
                    <el-radio-group @change="typeIdChage($event, items)" v-model="items.type_id">
                      <el-radio  label="1">自由模式</el-radio>
                      <el-radio  label="2">模板模式</el-radio>
                    </el-radio-group>
                    <el-select v-model="items.tpl_id" placeholder="请选择" v-if="items.type_id * 1 === 2" @change="tplChange($event, items)">
                      <el-option
                          v-for="item in taocanTemplates"
                          :key="item.tpl_id"
                          :label="item.name"
                          :value="item.tpl_id">
                      </el-option>
                    </el-select>
                  </div>
                  <span>{{ items.tableData.length }} 选</span>
                  <el-input
                    v-model="items.chooseCount"
                    placeholder="请输入"
                    size="mini"
                    :disabled="items.type_id * 1 === 2"
                    style="width: 80px; font-size: 18px"
                  />
                  <el-tooltip effect="light" placement="top">
                    <div slot="content">
                      N 选 M, 表示客户下单该套餐, 可以从该组N个选项中,
                      随意选出M项。
                      <br />注意M是可以大于N的。 <br />举例: 如果选项是 红茶2瓶,
                      绿茶2瓶. 配置的选项是 2 选 3。 <br />那么客户下单套餐时,
                      可以选 1份红茶2瓶, 2份绿茶2瓶。
                      <br />
                    </div>
                    <img
                      style="width: 14px; transform: translateY(-10px)"
                      :src="require('@/assets/img/btn_help.png')"
                      alt
                    />
                  </el-tooltip>
                </div>
                <div>
                  <span
                    class="primary-link cursor fs20"
                    @click="deleteGroupHandle(items)"
                    >删除该替换组</span
                  >
                </div>
              </div>
              <div class="table">
                <div class="thead">
                  <div
                    class="tr"
                    layout="row"
                    layout-align="space-between center"
                  >
                    <div class="th">行号</div>
                    <div class="th">单品名称</div>
                    <div class="th">分类</div>
                    <div class="th">单价</div>
                    <div class="th">
                      <span>数量</span>
                      <el-tooltip
                        class="item"
                        effect="light"
                        content="数量不填，默认为1"
                        placement="top"
                      >
                        <img
                          style="width: 14px; transform: translateY(-6px)"
                          :src="require('@/assets/img/btn_help.png')"
                          alt
                        />
                      </el-tooltip>
                    </div>
                    <div class="th">存货商品名</div>
                    <div class="th">类型</div>
                    <div class="th">营业类型</div>
                    <div class="th">状态</div>
                    <div class="th">操作</div>
                  </div>
                </div>
                <div class="tbody">
                  <div
                    class="tr"
                    layout="row"
                    layout-align="space-between center"
                    v-for="(item, index) in items.tableData"
                    :key="item.id"
                  >
                    <div class="td">{{ index + 1 }}</div>
                    <div class="td">{{ item.n }}</div>
                    <div class="td">{{ item.on }} > {{ item.tn }}</div>
                    <div class="td">{{ item.p }}</div>
                    <div class="td">
                      <el-input
                        v-model="item.pc"
                        placeholder="请输入数量"
                        size="mini"
                        :disabled="items.type_id * 1 === 2"
                      />
                    </div>
                    <div class="td">{{ item.mn }}</div>
                    <div class="td">{{ item.pt }}</div>
                    <div class="td">{{ item.bt }}</div>
                    <div class="td">{{ item.s }}</div>
                    <div class="td">
                      <span
                        class="primary-link cursor"
                        @click="deletePrdHandle('canChoose', items, item)"
                        v-if="items.type_id * 1 === 1"
                        >删除</span
                      >
                    </div>
                  </div>
                  <div class="no-data" v-if="fixedPrdTableData.length == 0">
                    <img
                      style="margin-top: 20px"
                      :src="require('@/assets/img/wu.png')"
                      alt
                    />
                    <p>暂无数据</p>
                  </div>
                </div>
              </div>
              <div class="add" layout="row" layout-align="center center">
                <span class="cursor primary-link fs20" v-if="items.type_id * 1 === 1">+</span>
                <span
                  class="cursor primary-link fs14"
                  v-if="items.type_id * 1 === 1"
                  @click="addPrdHandle('canChoose', items)"
                  >添加单品</span
                >
              </div>
            </div>
            <div class="add group" layout="row" layout-align="center center">
              <span class="cursor primary-link fs22">+</span> &nbsp;
              <span class="cursor primary-link fs20" @click="addGroupHandle"
                >新增替换组</span
              >
            </div>
          </div>
        </div>

        <div class="table-content table3 m-t-3">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">
                  <el-checkbox
                    v-model="checkAll"
                    :indeterminate="isIndeterminate"
                    @change="changeCheckboxHandle('all')"
                    >全选</el-checkbox
                  >
                </div>
                <div class="th">区域名称</div>
                <div class="th">区域状态</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="(item, index) in tableData"
                :key="item.id"
              >
                <div class="td">
                  <el-checkbox
                    v-model="item.checked"
                    @change="changeCheckboxHandle('item')"
                    >{{ index + 1 }}</el-checkbox
                  >
                </div>
                <div class="td">{{ item.n }}</div>
                <div class="td">{{ item.s == 1 ? "有效" : "无效" }}</div>
              </div>
              <div class="no-data" v-if="tableData.length == 0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 添加单品 -->
      <drawerAddPrd v-model="showChoosePrd" @changePrdList="changePrdList" prdType="1"/>

      <div
        class="form-btn"
        style="z-index: 1000"
        layout="row"
        layout-align="center center"
      >
        <el-button v-if="search" type="danger" @click="deleteHandle"
          >删除</el-button
        >
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit(2)">确定</el-button>
      </div>
    </el-drawer>

    <ImagePreview :dialogVisible="showImgDetails" :imgSrc="http + picUrl" @handleCloseClick="handleCloseClick" />
  </div>
</template>

<script>
import ImagePreview from "@/components/ImagePreview";

export default {
  data() {
    return {
      menuList: [], // 一二级菜单列表
      oneCateInfo: {},
      twoCateInfo: {},
      name: "", // 名称
      py: "", // 中文拼音
      englishName: "", // 英文名
      price: "", // 商品价格
      businessType: "", // 营业类型
      userYH: false,
      picUrl: "",
      http: "",
      showChoosePrd: false,
      showImgDetails: false, // 是否显示商品图片预览

      fixedPrdTableData: [], // 固定单品
      canChoosePrdTableData: [], // 可选替换组商品
      canChoosePrdMode: '1',
      canChooseGroupInfo: {}, // 可选替换组商品添加单品的详细息(通过此数据是否为空判断添加的是固定套餐组还是可选套餐组)

      tableData: [], // 区域出品库表格数据
      checkAll: false, // 出品库全选
      outLibOption: [], // 区域出品库下拉option
      setType: '', // 套餐类型,
      taocanTemplates: [], // 套餐可选组模板
      limitPc: false,
      limitPad: false,
      limitXcxEmp: false, 
      limitXcxCust: false,
    };
  },
  methods: {
    typeIdChage(v,item){
      console.log("typeIdChage:", v,item)
      item.tableData=[]
      item.chooseCount = 1
      item.tpl_id = ''
      this.$forceUpdate()

    },
    async tplChange(v, item){
      console.log(v)
      let res = await this.$api.BMS.Prd.get_prd_set_tpl({ id: v * 1 })
      console.log(res)
      if (res.code === 1) {
        item.chooseCount = res.data.sel_cnt
        let dtls = res.data.dtls || []
        // dtls.forEach(item => item.pc = item.c)
        dtls.forEach(item => {
          item.pc = item.c
          item.p = (item.p/100).toFixed(2)
          item.bt=item.b
        })
        
        item.tableData = dtls

      } else {
        this.$message.warning(res.msg);
      }
    },
    showPreImage() {
      this.showImgDetails = true;
    },
    handleCloseClick() {
      this.showImgDetails = false;
    },
    // 获取修改前数据
    async getPrdDetail() {
      const params = {
        id: this.currentInfo.id * 1,
      };
      try {
        const res = await this.$api.BMS.Prd.requestprdget_set(params);
        if (res.code == 1) {
          this.oneCateInfo = {
            id: res.data.one_cate_id,
            n: res.data.one_cate_name,
          };
          this.twoCateInfo = {
            id: res.data.two_cate_id,
            n: res.data.two_cate_name,
          };
          this.name = res.data.name || "";
          this.py = res.data.name_py || "";
          this.englishName = res.data.name_eng || "";
          this.setType = res.data.prd_type * 1;
          this.price = res.data.price || "";
          this.businessType = res.data.biz_type * 1;
          this.userYH = res.data.ut == 2;
          this.picUrl = res.data.pic_name || "";
          this.http = res.data.pic_prefix || "";

          // 处理固定单品
          this.fixedPrdTableData = (res.data.fix_items || []).map(item => ({
            ...item,
            // pc: item.pc === 1 ? '' : item.pc
          }));

          // 处理可替换组商品
          this.canChoosePrdTableData = (res.data.rpl_items || []).map(
            (item, i) => ({
              id: +new Date() + i * 1,
              chooseCount: item.sel_cnt || "",
              tableData: (item.items || []).map(subItem => ({
                ...subItem,
                // pc: subItem.pc === 1 ? '' : subItem.pc,
                s: subItem.s === 1 ? "有效" : (subItem.s === 2 ? "无效" : subItem.s),
              })),
              type_id: '1'
            })
          );

          let grp_tpl = res.data.grp_tpl || [];
          console.log('-'.repeat(100),this.canChoosePrdTableData)
          for(let i = 0; i < grp_tpl.length; i++) {
            if(grp_tpl[i].g > 0) {
              let index = grp_tpl[i].g
              let realIndex = index - 2
              console.log('realIndex:',realIndex)
              this.canChoosePrdTableData[realIndex].tpl_id = grp_tpl[i].t
              this.canChoosePrdTableData[realIndex].type_id = '2'
              // 处理模板模式下的 pc
              this.canChoosePrdTableData[realIndex].tableData = this.canChoosePrdTableData[realIndex].tableData.map(item => ({
                ...item,
                // pc: item.pc === 1 ? '' : item.pc
              }));
            }
          }

          this.limitPc = res.data.limit_pc === 1;
          this.limitPad = res.data.limit_pad === 1;
          this.limitXcxEmp = res.data.limit_xcx_emp === 1;
          this.limitXcxCust = res.data.limit_xcx_cust === 1;

          this.getTableData(res.data.sel_region_ids || []);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    // 获取一个级菜单信息
    getCateInfo() {
      const twoCateId = this.$route.query.menuId || 0;
      this.menuList.forEach((el) => {
        el.ss &&
          el.ss.forEach((ele) => {
            if (ele.id == twoCateId) {
              this.oneCateInfo = { ...el };
              this.twoCateInfo = { ...ele };
            }
          });
      });
    },

    async getTableData(areaList = []) {
      try {
        const res = await this.$api.BMS.Prd.requestprdass_items();
        if (res.code == 1) {
          this.menuList = res.data.cates || [];
          this.getCateInfo();

          this.outLibOption = (res.data.mklibs || []).filter(
            (item) => item.s == 1
          );

          this.tableData = (res.data.regions || []).map((item) => ({
            ...item,
            checked:
              this.type == 1
                ? true
                : !!areaList.find((items) => items == item.id),
          }));

          this.checkAll = this.tableData.every((item) => item.checked);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("出品库option请求失败", error);
      }
    },

    // 删除商品
    async deleteHandle() {
      const params = {
        ids: [this.currentInfo.id * 1],
      };
      try {
        const res = await this.$api.BMS.Prd.requestprddel(params);
        if (res.code == 1) {
          this.$emit("initSearchValHandle");
          this.onCancelDrawer();
          this.$message.success("删除成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("删除失败", error);
      }
    },

    changePrdList(prdList = []) {
      if (this.canChooseGroupInfo.id) {
        // 添加可选套餐组
        const canChoosePrdTableData = [...this.canChoosePrdTableData];
        canChoosePrdTableData.forEach((el) => {
          if (el.id == this.canChooseGroupInfo.id) {
            el.tableData = [
              ...el.tableData,
              ...prdList.map((item) => ({
                ...item,
                pc: "",
                s: item.s === 1 ? '有效' : (item.s === 2 ? '无效' : item.s)
              })),
            ].filter(
              (item, index, arr) =>
                arr.findIndex((items) => item.id == items.id) == index
            );
          }
        });
      } else {
        // 添加固定套餐组
        this.fixedPrdTableData = [
          ...this.fixedPrdTableData,
          ...prdList.map((item) => ({
            ...item,
            pc: "",
          })),
        ].filter(
          (item, index, arr) =>
            arr.findIndex((items) => item.id == items.id) == index
        );
      }
    },

    // 添加套餐组
    addGroupHandle() {
      this.canChoosePrdTableData = [
        ...this.canChoosePrdTableData,
        {
          id: +new Date(),
          chooseCount: "",
          tableData: [],
          type_id: "1",
        },
      ];
    },

    // 删除套餐组
    deleteGroupHandle(itemsInfo) {
      const index = this.canChoosePrdTableData.findIndex(
        (item) => item.id == itemsInfo.id
      );
      if (index > -1) this.canChoosePrdTableData.splice(index, 1);
    },

    // 添加单品
    addPrdHandle(type, itemInfo = {}) {
      if (type == "fixedPrd") {
        // 添加固定单品
        this.canChooseGroupInfo = {};
      } else {
        // 添加套餐组单品
        this.canChooseGroupInfo = { ...itemInfo };
      }
      this.showChoosePrd = true;
    },

    // 删除单品
    deletePrdHandle(type, itemsInfo, itemInfo) {
      if (type == "fixedPrd") {
        // 删除固定单品
        const index = this.fixedPrdTableData.findIndex(
          (item) => item.id == itemInfo.id
        );
        if (index > -1) this.fixedPrdTableData.splice(index, 1);
      } else {
        // 删除套餐组单品
        const canChoosePrdTableData = [...this.canChoosePrdTableData];
        const itemsIndex = canChoosePrdTableData.findIndex(
          (item) => item.id == itemsInfo.id
        );
        if (itemsIndex > -1) {
          const index = canChoosePrdTableData[itemsIndex].tableData.findIndex(
            (item) => item.id == itemInfo.id
          );
          if (index > -1) {
            canChoosePrdTableData[itemsIndex].tableData.splice(index, 1);
          }
        }
        this.canChoosePrdTableData = [...canChoosePrdTableData];
      }
    },

    uploadRequest(params) {
      if (!params.file) return;
      if (params.file.size / 1024 >= 500) {
        return this.$message.warning("图片大于500K，上传失败");
      }
      this.$api.BMS.Prd.requestOssPt().then((item) => {
        let res = item.data;
        let src =
          this.$overall.generateUUID() + "." + params.file.name.split(".")[1];
        let key = res.dir + src;

        this.http = res.host + "/" + res.dir;
        this.$api.BMS.Prd.handleUploadFile(
          res.host,
          {
            key: key,
            policy: res.policy,
            OSSAccessKeyId: res.accessid,
            success_action_status: "200", //让服务端返回200,不然，默认会返回204
            signature: res.signature,
          },
          params.file
        ).then((data) => {
          this.picUrl = src;
        });
      });
    },

    // 删除商品图片
    deleteImgHandle() {
      if (this.$refs.uploadPicUrlP) {
        this.$refs.uploadPicUrlP.clearFiles();
      }
      this.picUrl = "";
      this.http = "";
    },

    async onSubmit(force = 2) {
      if (this.name.length <= 0) return this.$message.warning("请输入名称");
      if (!this.price) return this.$message.warning("请输入价格");
      if (!this.businessType) return this.$message.warning("请选择营业类型");

      const fixPrdList = [];
      const canChoosePrdList = [];
      this.fixedPrdTableData.forEach((el) => {
        fixPrdList.push({
          pid: el.id,
          pc: el.pc === '' ? 1 : (el.pc || 1) * 1,
        });
      });

      this.canChoosePrdTableData.forEach((el) => {
        let itemPrdInfoList = [];
        if (el.type_id === '2') {
          // 如果是模板模式，只传一行记录
          itemPrdInfoList = [{
            pid: el.tpl_id * 1, // 使用模板 ID
            pc: 0
          }];
        } else {
          // 自由模式，保持原有逻辑
          el.tableData.forEach((ele) => {
            itemPrdInfoList.push({
              pid: ele.id,
              pc: ele.pc === '' ? 1 : (ele.pc || 1) * 1,
            });
          });
        }
        canChoosePrdList.push({
          sel_cnt: (el.chooseCount || 0) * 1,
          type_id: el.type_id * 1,
          items: itemPrdInfoList,
        });
      });

      const params = {
        name: this.name, // 商品名称
        one_cate_id: this.oneCateInfo.id * 1, // 一级分类id
        two_cate_id: this.twoCateInfo.id * 1, // 二级分类id
        name_eng: this.englishName || "", // 商品英文名
        name_py: this.py || "", // 商品拼音
        pic_name: this.picUrl, // 去掉前缀后的url地址
        price: this.price,
        biz_type: this.businessType * 1,
        use_type: this.userYH ? 2 : 1, // 用途限制 1 不限 2 仅用于优惠
        is_force: force,
        fix_items: fixPrdList,
        rpl_items: canChoosePrdList,
        prd_type: this.setType * 1, // 套餐类型
        region_ids: this.tableData
          .filter((item) => item.checked)
          .map((item) => item.id * 1), // 可点区域,
        ...(this.type == 2 && { id: this.currentInfo.id }),
        limit_pc: this.limitPc ? 1 : 2,
        limit_pad: this.limitPad ? 1 : 2,
        limit_xcx_emp: this.limitXcxEmp ? 1 : 2,
        limit_xcx_cust: this.limitXcxCust ? 1 : 2,
      };
      try {
        const api =
          this.type == 1 || this.type == 3
            ? "requestprdnew_set"
            : "requestprdsave_set";
        const res = await this.$api.BMS.Prd[api](params);
        if (res.code == 1) {
          this.onCancelDrawer();
          this.$emit("getTableData", true);
          this.$emit("getMenuList");
          this.$message.success("操作成功");
        } else if (res.code == 6) {
          this.onCancelDrawer();
          this.$emit("getTableData", true);
          this.$emit("getMenuList");
          this.$message.warning("创建成功，状态无效，" + res.msg);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("提交失败", error);
      }
    },
    onCancelDrawer() {
      this.show = false;
      if (this.$refs.uploadPicUrlP) {
        this.$refs.uploadPicUrlP.clearFiles();
      }
    },

    // 校验名称
    validator(val) {
      switch (val) {
        case "name":
          if (this.name == "") {
            this.$message.warning("请输入商品名称");
          } else if (this.$overall.character(this.name) > 60) {
            this.$message.warning("输入文字长度超过30");
          }
          break;
        case "englishName":
          if (this.$overall.character(this.englishName) > 60) {
            this.$message.warning("输入英文长度超过60");
          }
          break;
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData = this.tableData.map((item) => ({
            ...item,
            checked: this.checkAll,
          }));
          break;
        case "item":
          this.checkAll = this.tableData.every((item) => item.checked);
          break;
      }
    },

    resetHandle() {
      this.name = ""; // 名称
      this.py = ""; // 中文拼音
      this.englishName = ""; // 英文名
      this.price = ""; // 商品价格
      this.setType = ""; // 套餐类型
      this.businessType = ""; // 营业类型
      this.userYH = false;
      this.picUrl = "";
      this.http = ""; // 添加 http 重置
      this.fixedPrdTableData = []; // 固定单品
      this.canChoosePrdTableData = []; // 可选替换组商品
      this.canChooseGroupInfo = {};
      this.taocanTemplates = []; // 重置套餐模板列表
      
      // 重置上传组件
      if (this.$refs.uploadPicUrlP) {
        this.$refs.uploadPicUrlP.clearFiles();
      }
      this.limitPc = false;
      this.limitPad = false;
      this.limitXcxEmp = false;
      this.limitXcxCust = false;
    },

    // 修改后的方法来获取套餐模板列表
    async getTaocanTemplates() {
      try {
        const res = await this.$api.BMS.Prd.get_prd_set_tpl_list();
        if (res.code === 1) {
          let records = res.data.records || [];
          console.log('records:', records)
          let tpls = records.map(item => ({
            name: item.n,
            tpl_id: item.id
          }));
          console.log('tpls:', tpls)
          this.taocanTemplates = tpls
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.error("获取套餐模板列表失败", error);
      }
    },
  },
  mounted() {},
  props: {
    value: {
      default: false, // 是否显示drawer
    },
    type: {
      default: 1, // 1 新建  2 编辑  3 类似创建
    },
    search: {
      default: false,
    },
    currentInfo: {
      default: () => ({}),
    },
  },
  computed: {
    title() {
      return this.type == 1
        ? "新增套餐"
        : this.type == 2
        ? "编辑套餐"
        : "类似创建套餐";
    },
    // taocanTemplates() {
    //   let tpls = this.$store.state.cardPageInfo.resResultDataObj.taocanTemplate.filter(
    //       el => el.status * 1 == 1
    //   ) || []
    //   let tpls_real = tpls.map(item => {
    //     return {
    //       name: item.name,
    //       tpl_id: item.tpl_id
    //     }
    //   })
    //   tpls_real = [...new Set(tpls_real.map(v => JSON.stringify(v)))].map(s => JSON.parse(s))
    //   tpls_real.sort((a, b) => {
    //     const nameA = a.name.toUpperCase(); // 忽略大小写
    //     const nameB = b.name.toUpperCase(); // 忽略大小写
    //     if (nameA < nameB) {
    //       return 1;
    //     }
    //     if (nameA > nameB) {
    //       return -1;
    //     }
    //     return 0;
    //   })
    //   return tpls_real
    // },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      },
    },

    isIndeterminate() {
      return !this.checkAll && this.tableData.some((item) => item.checked);
    },
  },
  components: {
    drawerAddPrd: () => import("./drawerAddPrd.vue"),
    EllipsisTooltip: () => import("@/components/EllipsisTooltip.vue"), //根据路径导入组件，
    ImagePreview,
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.resetHandle();
          if (this.type == 1) {
            this.getTableData();
          } else {
            this.getPrdDetail();
          }
          this.getTaocanTemplates();
        } else {
          if (this.$refs.uploadPicUrlP) {
            this.$refs.uploadPicUrlP.clearFiles();
          }
        }
      },
      immediate: true,
    },
    name: {
      async handler(newVal) {
        const params = {
          str: newVal,
        };
        try {
          const res = await this.$api.UtilAuth.util.requestutilpy(params);
          if (res.code == 1) {
            this.py = res.data || "";
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("拼音获取失败", error);
        }
      },
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
@import "../../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.coll {
  margin: 20px 0 6px;

  .upload-btn {
    width: 90px;
    height: 90px;
    border: 1px dashed #555763;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .upload-btn-icon {
    margin-top: 20px;
  }

  .upload-btn-text {
    margin-top: 8px;
    font-size: 14px;
    color: rgb(217, 217, 217);
  }

  .prd-img {
    width: 90px;
    height: 90px;
    border: 1px dashed #555763;
    img {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
  }

  .add {
    padding: 10px;
    margin: 10px 0;
    background-color: #f8f8f8;
    &.group {
      margin-left: 50px;
    }
  }
}

/deep/input.el-input__inner {
  width: 100% !important;
}

.table-content {
  padding-left: 50px;
  box-sizing: border-box;
  &.table1,
  &.table2 {
    .th,
    .td {
      &:nth-child(1),
      &:nth-child(4),
      &:nth-child(5),
      &:nth-child(7),
      &:nth-child(8),
      &:nth-child(9),
      &:nth-child(10) {
        width: 30%;
      }
    }
  }
}
</style>


