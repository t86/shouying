<template>
  <div>
    <!-- 新增或修改商品 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="800px"
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
            <span>类型：</span>
          </div>
          <div
            class="value"
            layout="row"
            layout-align="start center"
            size="mini"
          >
            <el-select v-model="prdType" placeholder="请选择类型" size="mini">
              <el-option label="普通" :value="1"></el-option>
              <el-option label="时价特饮" :value="3"></el-option>
              <el-option label="时价小费" :value="4"></el-option>
              <el-option label="时价赔偿" :value="5"></el-option>
              <el-option label="联营" :value="6"></el-option>
              <el-option label="定价特饮" :value="13"></el-option>
              <el-option label="定价小费" :value="14"></el-option>
              <el-option label="定价赔偿" :value="15"></el-option>
            </el-select>
          </div>
        </div>
        <div class="price-group">
          <div class="price-group__title">
            <span class="red">*</span>
            <span>酒吧售价：</span>
          </div>
          <div class="price-group__fields">
            <div class="price-field">
              <div class="price-field__label">原价：</div>
              <el-input
                :disabled="isMarketPriceType"
                v-model="price"
                size="mini"
                maxlength="9"
              ></el-input>
            </div>
            <template v-if="!isMarketPriceType">
              <div class="price-field">
                <div class="price-field__label">会员价：</div>
                <el-input
                  v-model="mbPrice"
                  size="mini"
                  maxlength="9"
                ></el-input>
              </div>
              <div class="price-field">
                <div class="price-field__label">商务原价：</div>
                <el-input
                  v-model="bsPrice"
                  size="mini"
                  maxlength="9"
                ></el-input>
              </div>
              <div class="price-field">
                <div class="price-field__label">商务会员价：</div>
                <el-input
                  v-model="bsMbPrice"
                  size="mini"
                  maxlength="9"
                ></el-input>
              </div>
            </template>
          </div>
        </div>
        <div class="price-group" v-if="!isMarketPriceType">
          <div class="price-group__title">
            <span>包厢售价：</span>
          </div>
          <div class="price-group__desc">
            配置后,当卡台类型为"包厢"时,将使用新的一套价格
          </div>
          <div class="price-group__fields">
            <div class="price-field">
              <div class="price-field__label">包厢原价：</div>
              <el-input
                v-model="bxPrice"
                size="mini"
                maxlength="9"
              ></el-input>
            </div>
            <div class="price-field">
              <div class="price-field__label">包厢会员价：</div>
              <el-input
                v-model="bxMbPrice"
                size="mini"
                maxlength="9"
              ></el-input>
            </div>
            <div class="price-field">
              <div class="price-field__label">包厢商务原价：</div>
              <el-input
                v-model="bxBsPrice"
                size="mini"
                maxlength="9"
              ></el-input>
            </div>
            <div class="price-field">
              <div class="price-field__label">包厢商务会员价：</div>
              <el-input
                v-model="bxBsMbPrice"
                size="mini"
                maxlength="9"
              ></el-input>
            </div>
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
              :disabled="prdType != 1"
            >
              <el-option label="主营" :value="1"></el-option>
              <el-option label="非主营" :value="2"></el-option>
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
            <span>存货商品：</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <div
              layout="row"
              layout-align="start center"
              v-show="bindPrdList.length > 0"
            >
              <div
                v-for="(item, index) in bindPrdList"
                :key="index"
                style="padding: 5px; border-radius: 2px"
                layout="row"
                layout-align="start center"
                class="m-r-1"
              >
                <span style="color: #40404e">{{ item.n }}({{ item.un }})</span>
                <i class="el-icon-error cursor" @click="subPrdHandle(item)"></i>
              </div>
            </div>
            <el-button
              type="primary"
              v-show="bindPrdList.length > 0"
              @click="showBindPrd = true"
              >去修改</el-button
            >
            <el-button
              type="primary"
              v-show="!bindPrdList.length > 0"
              @click="showBindPrd = true"
              >去绑定</el-button
            >
          </div>
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

        <div class="table-content m-t-3">
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
                <div class="th">出品库</div>
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
                <div class="td">
                  <el-select
                    v-model="item.outLibVal"
                    size="mini"
                    placeholder="请选择出品库"
                  >
                    <el-option
                      v-for="item in outLibOption"
                      :key="item.id"
                      :label="item.n"
                      :value="item.id"
                    ></el-option>
                  </el-select>
                </div>
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

      <!-- 绑定商品 -->
      <drawerBindPrd v-model="showBindPrd" @changePrdList="changePrdList" />

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
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
    <ImagePreview :dialogVisible="showImgDetails" :imgSrc="http + picUrl" @handleCloseClick="handleCloseClick" />
  </div>
</template>

<script>
export default {
  data() {
    return {
      loaded: false, // 首次请求的数据是否加载完成
      menuList: [], // 一二级菜单列表
      oneCateInfo: {},
      twoCateInfo: {},
      name: "", // 名称
      py: "", // 中文拼音
      englishName: "", // 英文名
      prdType: "", // 类型
      price: "", // 商品价格（原价）
      mbPrice: "", // 会员价
      bsPrice: "", // 商务原价
      bsMbPrice: "", // 商务会员价
      bxPrice: "", // 包厢原价
      bxMbPrice: "", // 包厢会员价
      bxBsPrice: "", // 包厢商务原价
      bxBsMbPrice: "", // 包厢商务会员价
      businessType: "", // 营业类型
      userYH: false,
      bindPrdList: [], // 绑定商品列表
      picUrl: "",
      http: "",
      showBindPrd: false,
      showImgDetails: false, // 是否显示商品图片预览
      tableData: [], // 区域出品库表格数据
      checkAll: false, // 出品库全选
      outLibOption: [], // 区域出品库下拉option
      limitPc: false,
      limitPad: false, 
      limitXcxEmp: false,
      limitXcxCust: false,
    };
  },
  methods: {
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
        const res = await this.$api.BMS.Prd.requestprdget(params);
        if (res.code == 1) {
          this.oneCateInfo = {
            id: res.data.prd.one_cate_id,
            n: res.data.prd.one_cate_name,
          };
          this.twoCateInfo = {
            id: res.data.prd.two_cate_id,
            n: res.data.prd.two_cate_name,
          };
          this.name = res.data.prd.name || "";
          this.py = res.data.prd.name_py || "";
          this.englishName = res.data.prd.name_eng || "";
          this.prdType = res.data.prd.prd_type * 1;
          this.price =
            this.prdType == 3 || this.prdType == 4 || this.prdType == 5
              ? "时价"
              : res.data.prd.price || "";
          this.mbPrice = res.data.prd.mb_price || "";
          this.bsPrice = res.data.prd.bs_price || "";
          this.bsMbPrice = res.data.prd.bs_mb_price || "";
          this.bxPrice = res.data.prd.bx_price || "";
          this.bxMbPrice = res.data.prd.bx_mb_price || "";
          this.bxBsPrice = res.data.prd.bx_bs_price || "";
          this.bxBsMbPrice = res.data.prd.bx_bs_mb_price || "";
          this.businessType = res.data.prd.biz_type * 1;
          this.userYH = res.data.prd.use_type == 2;
          if ([3, 4, 5].includes(this.prdType)) {
            this.mbPrice = "";
            this.bsPrice = "";
            this.bsMbPrice = "";
            this.bxPrice = "";
            this.bxMbPrice = "";
            this.bxBsPrice = "";
            this.bxBsMbPrice = "";
          }
          this.bindPrdList = res.data.prd.m_id
            ? [
                {
                  id: res.data.prd.m_id,
                  n: res.data.prd.m_name,
                  un: res.data.prd.m_uint_name,
                },
              ]
            : [];
          this.picUrl = res.data.prd.pic_name || "";
          this.http = res.data.prd.pic_prefix || "";
          this.limitPc = res.data.prd.limit_pc === 1;
          this.limitPad = res.data.prd.limit_pad === 1;
          this.limitXcxEmp = res.data.prd.limit_xcx_emp === 1;
          this.limitXcxCust = res.data.prd.limit_xcx_cust === 1;

          this.getTableData(res.data.region_prds || []);

          this.$nextTick(() => {
            this.loaded = true;
          });
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
                : !!areaList.find((items) => items.rid == item.id),
            outLibVal:
              this.type == 1
                ? this.oneCateInfo.fmk
                : (areaList.find((items) => items.rid == item.id) || {}).mid ||
                  this.oneCateInfo.fmk,
          }));

          this.checkAll = this.tableData.every((item) => item.checked);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("出品库option请求失败", error);
      }
    },

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
        this.$message.warning("删除失败", error)
      }
    },

    changePrdList(prdList = []) {
      this.bindPrdList = [...prdList];
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
      this.picUrl = "";
      this.http = "";
      if (this.$refs.uploadPicUrlP) {
        this.$refs.uploadPicUrlP.clearFiles();
      }
    },

    // 校验会员价依赖与上限
    validateMemberPrice(originPrice, memberPrice, originLabel, memberLabel) {
      if (memberPrice && !originPrice) {
        this.$message.warning(`配置${memberLabel}，请先配置${originLabel}`);
        return false;
      }
      if (memberPrice && Number(memberPrice) > Number(originPrice)) {
        this.$message.warning(`${memberLabel}不得超过${originLabel}`);
        return false;
      }
      return true;
    },

    async onSubmit() {
      if (this.name.length <= 0) return this.$message.warning("请输入名称");
      if (!this.prdType) return this.$message.warning("请选择类型");
      if (!this.price) return this.$message.warning("请输入价格");
      if (!this.businessType) return this.$message.warning("请选择营业类型");

      // 会员价校验：需先有对应原价且会员价<=原价
      const memberChecks = [
        this.validateMemberPrice(this.price, this.mbPrice, "酒吧原价", "酒吧会员价"),
        this.validateMemberPrice(this.bsPrice, this.bsMbPrice, "酒吧商务原价", "酒吧商务会员价"),
        this.validateMemberPrice(this.bxPrice, this.bxMbPrice, "包厢原价", "包厢会员价"),
        this.validateMemberPrice(this.bxBsPrice, this.bxBsMbPrice, "包厢商务原价", "包厢商务会员价"),
      ];
      if (memberChecks.includes(false)) return false;
      const params = {
        name: this.name, // 商品名称
        one_cate_id: this.oneCateInfo.id * 1, // 一级分类id
        two_cate_id: this.twoCateInfo.id * 1, // 二级分类id
        name_eng: this.englishName || "", // 商品英文名
        name_py: this.py || "", // 商品拼音
        pic_name: this.picUrl, // 去掉前缀后的url地址
        price: this.price == "时价" ? "0" : this.price,
        mb_price: this.mbPrice || "",
        bs_price: this.bsPrice || "",
        bs_mb_price: this.bsMbPrice || "",
        bx_price: this.bxPrice || "",
        bx_mb_price: this.bxMbPrice || "",
        bx_bs_price: this.bxBsPrice || "",
        bx_bs_mb_price: this.bxBsMbPrice || "",
        prd_type: this.prdType * 1, // 商品类型  1 存货(需关联erp) 7 普通商品(不需关联erp,默认主营) 2 套餐 3 存货花篮(需关联erp,且分成) 8 普通花篮(不需关联erp,且分成) 4 小费(不需关联erp,且分成) 5 赔偿(不需关联erp,且非主营) 6 联营(不需关联erp,且主营)
        biz_type: this.businessType * 1, // 营业类型  1 主营 2 非主营 3 非主营(分成) (prd_type 1,7 可指定1,2,3 ;   2 填0 ;   3,8,4 填3 ;   5,6 填2)
        // erp_prd_id: this.newmerchandise.inventory.id,  // erp商品Id, 普通商品,花篮商品 需提供
        use_type: this.userYH ? 2 : 1, // 用途限制 1 不限 2 仅用于优惠
        regions: this.tableData
          .filter((item) => item.checked)
          .map((item) => item.id * 1), // 可点区域
        mklibs: this.tableData
          .filter((item) => item.checked)
          .map((item) => item.outLibVal * 1), // 可点区域对应的出品库
        mat_id: this.bindPrdList.length == 0 ? 0 : this.bindPrdList[0].id, // int64  关联的存货商品Id
        limit_pc: this.limitPc ? 1 : 2,
        limit_pad: this.limitPad ? 1 : 2,
        limit_xcx_emp: this.limitXcxEmp ? 1 : 2,
        limit_xcx_cust: this.limitXcxCust ? 1 : 2,
        ...(this.type == 2 && { id: this.currentInfo.id }),
      };
      try {
        const api = this.type == 1 ? "requestprdnew" : "requestprdsave";
        const res = await this.$api.BMS.Prd[api](params);
        if (res.code == 1) {
          this.onCancelDrawer();
          this.$emit("getTableData", true);
          this.$emit("getMenuList");
          this.$message.success("操作成功");
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

    // 删除绑定存货中的子选项
    subPrdHandle(itemInfo) {
      const bindPrdList = [...this.bindPrdList];
      const index = bindPrdList.findIndex((item) => item.id == itemInfo.id);
      if (index > -1) bindPrdList.splice(index, 1);
      this.bindPrdList = [...bindPrdList];
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
      this.prdType = ""; // 类型
      this.price = ""; // 商品价格（原价）
      this.mbPrice = ""; // 会员价
      this.bsPrice = ""; // 商务原价
      this.bsMbPrice = ""; // 商务会员价
      this.bxPrice = ""; // 包厢原价
      this.bxMbPrice = ""; // 包厢会员价
      this.bxBsPrice = ""; // 包厢商务原价
      this.bxBsMbPrice = ""; // 包厢商务会员价
      this.businessType = ""; // 营业类型
      this.userYH = false;
      this.bindPrdList = []; // 绑定商品列表
      this.picUrl = "";
      if (this.$refs.uploadPicUrlP) {
        this.$refs.uploadPicUrlP.clearFiles();
      }
      this.limitPc = false;
      this.limitPad = false;
      this.limitXcxEmp = false;
      this.limitXcxCust = false;
    },
  },
  mounted() {},
  props: {
    value: {
      default: false, // 是否显示drawer
    },
    type: {
      default: 1,
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
      return this.type == 1 ? "新增单品" : "编辑单品";
    },

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
    isMarketPriceType() {
      return [3, 4, 5].includes(this.prdType * 1);
    },
  },
  components: {
    drawerBindPrd: () => import("./drawerBindPrd.vue"),
    ImagePreview: () =>  import("@/components/ImagePreview"),
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          if (this.type == 1) {
            this.resetHandle();
            this.getTableData();
            this.loaded = true;
          } else {
            this.getPrdDetail();
            this.loaded = false;
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
    prdType(newVal) {
      if (!this.loaded) return false;
      if (newVal != 1) {
        this.businessType = 2;
      }
      if (newVal == 1 || newVal == 6) {
        this.businessType = 1;
      }
      if (newVal == 1) {
        // this.businessType = 1
        this.price = "";
      }
      if (this.isMarketPriceType) {
        this.price = "时价";
        this.mbPrice = "";
        this.bsPrice = "";
        this.bsMbPrice = "";
        this.bxPrice = "";
        this.bxMbPrice = "";
        this.bxBsPrice = "";
        this.bxBsMbPrice = "";
      }
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
}

.table {
  .th,
  .td {
    &:nth-child(3) {
      width: 80%;
    }
  }
}

.price-group {
  margin: 16px 0;

  &__title {
    font-size: 14px;
    font-weight: 500;
    color: #40404e;
    display: flex;
    align-items: center;

    .red {
      margin-right: 6px;
      color: #D9001B;
    }
  }

  &__desc {
    font-size: 12px;
    color: #666;
    margin-top: 4px;
  }

  &__fields {
    margin-top: 12px;
    display: flex;
    flex-wrap: wrap;
  }
}

.price-field {
  width: 50%;
  min-width: 240px;
  margin-bottom: 12px;
  display: flex;
  align-items: center;

  &__label {
    width: 110px;
    text-align: right;
    margin-right: 10px;
    color: #40404e;
    white-space: nowrap;
  }

  .el-input {
    width: 190px;
    max-width: 65%;
  }
}

@media (max-width: 900px), (orientation: portrait) {
  .price-field {
    width: 100%;
    min-width: 220px;

    .el-input {
      width: 100%;
      max-width: none;
    }
  }
}
</style>
