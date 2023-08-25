<template>
  <div class="Singless">
    <div class="searchselect">
      <el-input
        v-model="nr"
        prefix-icon="el-icon-search"
        class="classifysearch"
        placeholder="搜索"
        clearable
        @clear="dainj"
      />
      <div class="collapse" v-show="sfshow" :style="{'max-height':`${MaxHeight}px`}">
        <el-collapse v-model="stairNames" @change="stairhandleChange" accordion>
          <el-collapse-item name="全部">
            <!-- <span slot="title" class=" " >
                            <img class="icons" src="@/assets/img/文件夹.png"  alt="">
                            <router-link to="/ERP/mat/mocate" class="routerlinkyus" >
                                <div>全部</div>
                            </router-link>
            </span> #162C69-->
            <router-link
              to="/BMS/Prds/Ocate"
              :style="{'background-color':gaibland=='全部'?'#f9f9f9':''}"
              slot="title"
              class="routerlinkyus collapse-title"
            >
              <img class="icons" src="@/assets/img/文件夹.png" alt />
              <ellipsis-tooltip text="全部"></ellipsis-tooltip>
            </router-link>
            <!-- 一级分类列表 stair -->
            <div v-for="(stair,i) in classifys" :key="i" class="stair">
              <el-collapse v-model="secondNames" @change="secondhandleChange" accordion>
                <el-collapse-item :name="stair.id+''">
                  <span
                    slot="title"
                    :style="{'background-color':gaibland==stair.id?'#f9f9f9':''}"
                    class="collapse-title"
                    style="width: calc(100% - 18px);"
                  >
                    <img class="icons" src="@/assets/img/文件夹.png" alt />
                    <router-link
                      :to="`/BMS/Prds/tcate/${stair.id}`"
                      class="routerlinkyus"
                      style="width: calc(100% - 18px);"
                    >
                      <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
                    </router-link>
                  </span>
                  <!-- 二级分类列表 second -->
                  <div
                    v-for="(second,j) in stair.subs"
                    :style="{'background-color':gaibland==second.id?'#D7E9FF':''}"
                    :key="j"
                    class="second"
                    @click="materialhandleChange(second.id+'')"
                  >
                    <img class="icons" src="@/assets/img/文件夹.png" alt />
                    <router-link
                      :to="`/BMS/Prds/Prd/${second.id}`"
                      class="routerlinkyus"
                      style="width: calc(100% - 18px);"
                    >
                      <ellipsis-tooltip :text="second.n || '-----'"></ellipsis-tooltip>
                    </router-link>
                  </div>
                </el-collapse-item>
              </el-collapse>
            </div>
          </el-collapse-item>
        </el-collapse>
      </div>
      <div class="eresult" v-show="!sfshow">
        <div class="lbao" v-show="searchesult.sl > 0">
          <div class="liebia" v-show="searchesult.yij.length > 0">一级分类列表：</div>
          <div class="yansnafe" v-show="searchesult.yij.length > 0">
            <div
              class="lbnrs"
              v-for="(stair,i) in searchesult.yij"
              :key="i"
              @click="xuanzyij(stair.id+'')"
            >
              <img class="icons" src="@/assets/img/文件夹.png" alt />
              <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
            </div>
          </div>
          <div class="liebia" v-show="searchesult.erj.length > 0">二级分类列表：</div>
          <div class="yansnafe" v-show="searchesult.erj.length > 0">
            <div
              class="lbnrs"
              v-for="(stair,i) in searchesult.erj"
              :key="i"
              @click="xuanzerj(stair.id+'',stair.yij+'')"
            >
              <img class="icons" src="@/assets/img/文件夹.png" alt />
              <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
            </div>
          </div>
          <div class="liebia" v-show="searchesult.wl.length > 0">商品列表：</div>
          <div class="yansnafe" v-show="searchesult.wl.length > 0">
            <div class="lbnrs" v-for="(stair,i) in searchesult.wl" :key="i" @click="xuanzwl(stair)">
              <img class="icons" src="@/assets/img/商品列表.png" alt />
              <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
            </div>
          </div>
        </div>
        <div class="meiy" v-show="searchesult.sl == 0">
          <img src="../../../../assets/img/wu.png" alt />
          <div>未搜索到相关数据</div>
        </div>
      </div>
    </div>
    <div style="width: calc(100% - 200px);">
      <router-view />
    </div>

    <div class="Prds">
      <!-- 编辑单品 -->
      <div class="dialogPrinter" v-if="QuantityProduction">
        <el-dialog
          title="编辑单品"
          :visible.sync="QuantityProduction"
          @close="QuantityProduction = false"
          :close-on-click-modal="false"
        >
          <!-- <div class="biaot">基本属性</div> -->
          <el-form label-position="left">
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>分类：
                </div>
                <div class="controlling">
                  {{one_cate_name}}
                  <i class="el-icon-arrow-right"></i>
                  {{two_cate_name}}
                </div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>名称：
                </div>
                <el-input
                  v-model="newmerchandise.name"
                  placeholder="请输入名称"
                  class="controlling"
                  ref="xidhf"
                  :class="form_rule_msg_name?'error':''"
                  @blur="validator('name')"
                />
                <div class="cwts">{{form_rule_msg_name}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>拼音简写：
                </div>
                <div
                  style="color:#40404e;line-height: 40px;"
                  class="controlling"
                >{{newmerchandise.phoneticize}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>英文名：
                </div>
                <el-input
                  v-model="newmerchandise.English"
                  placeholder="请输入英文名"
                  class="controlling"
                  :class="form_rule_msg_English?'error':''"
                  @blur="validator('English')"
                />
                <div class="cwts">{{form_rule_msg_English}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>类型：
                </div>
                <el-select v-model="newmerchandise.SKUtype" placeholder="请选择类型" class="controlling">
                  <el-option label="普通" value="1"></el-option>
                  <el-option label="特饮" value="3"></el-option>
                  <el-option label="小费" value="4"></el-option>
                  <el-option label="赔偿" value="5"></el-option>
                  <el-option label="联营" value="6"></el-option>
                  <el-option label="定价特饮" value="13"></el-option>
                  <el-option label="定价小费" value="14"></el-option>
                </el-select>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>单价：
                </div>
                <el-input
                  v-show="!newmerchandise.marketprices"
                  v-model="newmerchandise.price"
                  placeholder="请输入单价"
                  class="controlling"
                />
                <div
                  v-show="newmerchandise.marketprices"
                  class="controlling"
                >{{newmerchandise.price}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>营业类型：
                </div>
                <el-select
                  v-model="newmerchandise.businesstype"
                  placeholder="请选择营业类型"
                  class="controlling"
                  :disabled="newmerchandise.forbidden"
                >
                  <el-option label="主营" value="1"></el-option>
                  <el-option label="非主营" value="2"></el-option>
                  <!-- <el-option label="非主营（分成）" value="3"></el-option> -->
                </el-select>
              </div>
            </div>
          <div class="compatibil">
            <div class="compatibility" layout="row" layout-align="start center">
              <div class="mandatory">
                用途限制：
              </div>
              <el-checkbox v-model="newmerchandise.usedSubCheckboxVal">仅用于优惠</el-checkbox>
            </div>
            <div style="color: rgb(255, 47, 75);margin-top: 5px;margin-left: 140px">勾选后，该商品服务员点单和客人点单不可见，仅用于优惠</div>
          </div>
            <div class="compatibil" v-show="newmerchandise.Inventorygoods">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>存货商品：
                  <!-- <span class="reqfieldsd">*</span>存货商品： -->
                </div>
                <div
                  layout="row"
                  layout-align="start center"
                  v-show="newmerchandise.inventory.length>0"
                >
                  <div
                    v-for="(item,index) in newmerchandise.inventory"
                    :key="index"
                    style="padding:5px;border-radius:2px"
                    layout="row"
                    layout-align="start center"
                    class="m-r-1"
                  >
                    <span style="color:#40404e">{{item.n}}({{item.un}})</span>
                    <i class="el-icon-error cursor" @click="subInventoryHandle(item)"></i>
                  </div>
                </div>
                <el-button
                  type="primary"
                  v-show="newmerchandise.inventory.length>0"
                  @click="binding"
                >去修改</el-button>
                <el-button
                  type="primary"
                  v-show="!newmerchandise.inventory.length>0"
                  @click="binding"
                >去绑定</el-button>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>商品图片：
                </div>
                <div v-show="!newmerchandise.pic_url" style="margin-left: 10px">
                  <el-upload
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
                          style="height: 30px;width: 30px;"
                          src="../../../../assets/img/添加.png"
                          alt
                        />
                      </div>
                      <div class="upload-btn-text" style="color: #40404e;">上传</div>
                    </div>
                  </el-upload>
                  <div style="color: rgb(255, 47, 75);margin-top: 5px">点击上传图片，仅支持：jpg、png的格式；</div>
                </div>
                <div
                  v-show="newmerchandise.pic_url"
                  style="display: flex;flex-direction: column;margin-left: 10px"
                >
                  <div class="prd_img" layout="row" layout-align="center center">
                    <img
                      v-if="newmerchandise.pic_url"
                      ref="prdImgLoad"
                      @load="prdImgLoadHandle"
                      style="width:90px;height:90px"
                      :src="`${http}${newmerchandise.pic_url}`"
                      alt
                    />
                  </div>
                  <div class="prd_img_btn">
                    <div class="prd_img_btn_l" @click="imgDetails = true">查看</div>
                    <div class="prd_img_btn_r" @click="delImg">删除</div>
                  </div>
                </div>
              </div>
            </div>
          </el-form>
          <el-form label-position="left">
            <div class="compatibil">
              <div class="compatibility">
                <table class="extend-unit">
                  <thead class="mmodity">
                    <tr>
                      <th>
                        <el-checkbox
                          :indeterminate="nature_isIndeterminate"
                          v-model="nature_checkAll"
                          @change="nature_handleCheckAllChange"
                        >行号</el-checkbox>
                      </th>
                      <th>区域名称</th>
                      <th>出品库</th>
                      <th>区域状态</th>
                    </tr>
                  </thead>
                  <tbody class="limiting">
                    <tr
                      v-for="(item,i) in regions"
                      :key="i"
                      class="drag-list"
                      :class="nature_checkedCities.includes(item.id)? 'drag-list-check':''"
                    >
                      <td>
                        <el-checkbox-group
                          v-model="nature_checkedCities"
                          @change="nature_handleCheckedCitiesChange"
                        >
                          <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                        </el-checkbox-group>
                      </td>
                      <td :style="{'color':item.s==1?'':'#595959'}">{{item.n}}</td>
                      <td>
                        <el-select v-model="regions[i].fmk" placeholder="请选择出品库">
                          <el-option
                            v-for="each in regions[i].mklibs"
                            :key="each.id"
                            :label="each.n"
                            :value="each.id"
                          ></el-option>
                        </el-select>
                      </td>
                      <td :style="{'color':item.s==1?'':'#595959'}">{{item.s == 1?'有效':'无效'}}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </el-form>
          <span slot="footer" class="dialog-footer">
            <el-button @click="showOrHideDetailDialog" type="danger">删除</el-button>
            <el-button @click="QuantityProduction = false">取消</el-button>
            <el-button type="primary" v-show="!singlecommodities" @click="savecommodity">保存</el-button>
          </span>
        </el-dialog>
      </div>
      <!-- 绑定erp商品 -->
      <div class="user-defined" v-show="ERPcommodity">
        <el-dialog
          title="绑定erp商品"
          @close="ERPcommodity = false"
          :visible.sync="ERPcommodity"
          :close-on-click-modal="false"
        >
          <div class="in_sum-rkrq">
            <div class="rkrq">
              <span>商品：</span>
              <el-cascader
                clearable
                :options="dept_items"
                :props="optionProps"
                v-model="dept_code"
                :show-all-levels="false"
                popper-class="liebdwd"
                ref="cascaderRef"
              ></el-cascader>
            </div>
            <div class="rkrq">
              <el-input v-model="erp_prds.name" placeholder="请输入erp商品名称 模糊查询"></el-input>
            </div>
            <div class="rkrq">
              <el-button type="primary" @click="prderp_prds">查询</el-button>
            </div>
          </div>
          <div style="display: inline-block;width: 602px; ">
            <table class="zhuixiaoi">
              <thead class="mmodity">
                <tr>
                  <th style="border-left:1px solid #f5f5f5">行号</th>
                  <th>erp商品名称</th>
                  <th>erp商品分类树描述</th>
                  <th>状态</th>
                </tr>
              </thead>
              <tbody class="limiting">
                <tr
                  v-for="(item,i) in erps_prdss"
                  :key="i"
                  class="drag-list"
                  draggable="true"
                  :class="checkedCitispes.includes(item.id)? 'drag-list-check':''"
                >
                  <td :style="{'color':item.s=='无效'?'#595959':''}">
                    <el-checkbox-group v-model="checkedCitispes">
                      <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                    </el-checkbox-group>
                    <!-- <el-radio v-model="checkedCitispes" :label="item.c">{{i+1}}&emsp;&ensp;</el-radio> -->
                  </td>
                  <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                  <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.cp}}</td>
                  <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
                </tr>
                <tr class="drag-list" v-if="erps_prdss.length<1">
                  <td class="nodata">
                    <img v-show="controlpicture ==1" src="../../../../assets/img/wu.png" alt />
                    <img v-show="controlpicture ==2" src="../../../../assets/img/空-请检索.png" alt />
                    <img v-show="controlpicture ==3" src="../../../../assets/img/加载中.png" alt />
                    <div v-show="controlpicture ==1" class="hint">暂无数据</div>
                    <div v-show="controlpicture ==2" class="hint">空-请检索</div>
                    <div v-show="controlpicture ==3" class="hint">加载中...</div>
                  </td>
                </tr>
              </tbody>
            </table>
            <div class="Pagination">
              <el-pagination
                background
                layout="prev, pager, next"
                @current-change="handleCurrentChange"
                :page-size="erp_prds.page_size"
                :total="erp_prds.rowcnt"
              ></el-pagination>
            </div>
          </div>

          <span slot="footer" class="dialog-footer">
            <el-button @click="ERPcommodity = false">取消</el-button>
            <el-button type="primary" @click="bindingERp">绑定</el-button>
          </span>
        </el-dialog>
      </div>

      <!-- 编辑套餐 -->
      <div class="dialogsetmeal" v-if="newsetmeals">
        <el-dialog
          title="编辑套餐"
          ref="rollbott"
          :visible.sync="newsetmeals"
          @close="newsetmeals = false"
          :close-on-click-modal="false"
        >
          <!-- <div class="biaot">基本属性</div> -->
          <el-form label-position="left">
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>分类：
                </div>
                <div class="controlling">
                  {{one_cate_name}}
                  <i class="el-icon-arrow-right"></i>
                  {{two_cate_name}}
                </div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>名称：
                </div>
                <el-input
                  v-model="setmeals.name"
                  placeholder="请输入名称"
                  class="controlling"
                  ref="xidhf"
                  :class="form_rule_msg_name?'error':''"
                  @blur="validator('tc_name')"
                />
                <div class="cwts">{{form_rule_msg_name}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>拼音简写：
                </div>
                <div
                  style="color:#40404e;line-height: 40px;"
                  class="controlling"
                >{{setmeals.phoneticize}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>英文名：
                </div>
                <el-input
                  v-model="setmeals.English"
                  placeholder="英文名"
                  class="controlling"
                  :class="form_rule_msg_English?'error':''"
                  @blur="validator('tc_English')"
                />
                <div class="cwts">{{form_rule_msg_English}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>单价：
                </div>
                <el-input v-model="setmeals.price" placeholder="单价" class="controlling" />
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>营业类型：
                </div>
                <el-select
                  v-model="setmeals.businesstype"
                  placeholder="请选择营业类型"
                  class="controlling"
                >
                  <el-option label="主营" value="1"></el-option>
                  <el-option label="非主营" value="2"></el-option>
                  <el-option label="继承单品配置" value="3"></el-option>
                </el-select>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  用途限制：
                </div>
                <el-checkbox v-model="setmeals.usedSubCheckboxVal">仅用于优惠</el-checkbox>
              </div>
              <div style="color: rgb(255, 47, 75);margin-top: 5px;margin-left: 140px">勾选后，该商品服务员点单和客人点单不可见，仅用于优惠</div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>商品图片：
                </div>
                <div v-show="!setmeals.pic_url" style="margin-left: 10px">
                  <el-upload
                    action
                    :show-file-list="false"
                    :limit="1"
                    ref="uploadPicUrlT"
                    accept=".jpg, .png"
                    :with-credentials="true"
                    :http-request="uploadRequest"
                  >
                    <div class="upload-btn">
                      <div class="upload-btn-icon">
                        <img
                          style="height: 30px;width: 30px;"
                          src="../../../../assets/img/添加.png"
                          alt
                        />
                      </div>
                      <div class="upload-btn-text" style="color: #40404e;">上传</div>
                    </div>
                  </el-upload>
                  <div style="color: rgb(255, 47, 75);margin-top: 5px">点击上传图片，仅支持：jpg、png的格式；</div>
                </div>
                <div
                  v-show="setmeals.pic_url"
                  style="display: flex;flex-direction: column;margin-left: 10px"
                >
                  <div class="prd_img" layout="row" layout-align="center center">
                    <img
                      v-if="setmeals.pic_url"
                      ref="prdImgLoad"
                      @load="prdImgLoadHandle"
                      style="width:90px;height:90px"
                      :src="`${http}${setmeals.pic_url}`"
                      alt
                    />
                  </div>
                  <div class="prd_img_btn">
                    <div class="prd_img_btn_l" @click="imgDetails = true">查看</div>
                    <div class="prd_img_btn_r" @click="delImg">删除</div>
                  </div>
                </div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <!-- <span class="reqfieldsd">*</span> -->
                  固定单品：
                </div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <table class="extend-unit">
                  <thead class="mmodity">
                    <tr>
                      <th style="border-left: 1px solid #f5f5f5;">行号</th>
                      <th>单品名称</th>
                      <th>分类</th>
                      <th>单价</th>
                      <th class="tbdgf">
                        <span>数量</span>
                        <el-tooltip class="item" effect="light" content="数量不填，默认为1" placement="top">
                          <img src="../../../../assets/img/问号.png" alt />
                        </el-tooltip>
                      </th>
                      <th>存货商品名</th>
                      <th>类型</th>
                      <th>营业类型</th>
                      <th>状态</th>
                      <th>操作</th>
                    </tr>
                  </thead>
                  <tbody class="limiting">
                    <tr v-for="(item,i) in setmeallist" :key="i" class="drag-list">
                      <td
                        :style="{'color':item.s=='2'?'#595959':'','border-left':'1px solid #f5f5f5'}"
                      >{{i+1}}</td>
                      <td :style="{'color':item.s=='2'?'#595959':''}">
                        <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                      </td>
                      <td :style="{'color':item.s=='2'?'#595959':''}">
                        {{item.on}}
                        <i class="el-icon-arrow-right"></i>
                        {{item.tn}}
                      </td>
                      <td :style="{'color':item.s=='2'?'#595959':''}">
                        <div class="money">{{item.p}}</div>
                      </td>
                      <td :style="{'color':item.s=='2'?'#595959':''}">
                        <el-input v-model="item.pc" placeholder="请输入数量" class="alignment" />
                      </td>
                      <td :style="{'color':item.s=='2'?'#595959':''}">
                        <ellipsis-tooltip
                          :text="item.mn || '-----'"
                          class="one-txt-cut"
                          style="width:140px"
                        ></ellipsis-tooltip>
                      </td>
                      <td :style="{'color':item.s=='2'?'#595959':''}">{{item.pt}}</td>
                      <td :style="{'color':item.s=='2'?'#595959':''}">{{item.bt}}</td>
                      <td :style="{'color':item.s=='2'?'#595959':''}">{{item.s==1?'有效':'无效'}}</td>
                      <td style="color: #438dfd" @click="dpdelete(i)">删除</td>
                    </tr>
                    <tr class="drag-list" v-if="setmeallist.length<1">
                      <td class="nodata" colspan="10" style="border-left: 1px solid #f5f5f5;">
                        <img src="../../../../assets/img/wu.png" alt />
                        <div class="hint">暂无数据</div>
                      </td>
                    </tr>
                    <tr class="drag-list" @click="additional(true)">
                      <td class="Theewitem" style="border-left: 1px solid #f5f5f5;">
                        <div>＋</div>
                        <div>添加单品</div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>可替换：
                </div>
              </div>
            </div>
            <div
              class="keorganize"
              :class="{'highlight' : item.deletejudge}"
              v-for="(item,j) in substitute"
              :key="j"
            >
              <div class="grouphandle">
                <div class="choice">
                  {{item.items.length}}&ensp;选 &ensp;
                  <el-input
                    v-model="item.sel_cnt"
                    placeholder
                    style="width:80px; font-size: 20px;"
                  />
                  <el-tooltip class="hintimg" effect="light" placement="top">
                    <div slot="content">
                      N 选 M, 表示客户下单该套餐, 可以从该组N个选项中, 随意选出M项。
                      <br />注意M是可以大于N的。
                      <br />举例: 如果选项是 红茶2瓶, 绿茶2瓶. 配置的选项是 2 选 3。
                      <br />那么客户下单套餐时, 可以选 1份红茶2瓶, 2份绿茶2瓶。
                      <br />
                    </div>
                    <img src="../../../../assets/img/问号.png" alt />
                  </el-tooltip>
                </div>
                <div
                  v-show="!item.deletejudge"
                  class="deletereplace"
                  @click="item.deletejudge = true"
                >－删除该替换组</div>
                <div v-show="item.deletejudge" style="display: flex;">
                  <div class="deletereplace" @click="item.deletejudge = false">取消</div>
                  <div class="reddeletereplace" @click="deletereplace(j)">删除</div>
                </div>
              </div>
              <table class="extend-unit">
                <thead class="mmodity">
                  <tr>
                    <th style="border-left: 1px solid #f5f5f5;">行号</th>
                    <th>单品名称</th>
                    <th>分类</th>
                    <th>单价</th>
                    <th class="tbdgf">
                      <span>数量</span>
                      <el-tooltip class="item" effect="light" content="数量不填，默认为1" placement="top">
                        <img src="../../../../assets/img/问号.png" alt />
                      </el-tooltip>
                    </th>
                    <th>存货商品名</th>
                    <th>类型</th>
                    <th>营业类型</th>
                    <th>状态</th>
                    <th>操作</th>
                  </tr>
                </thead>
                <tbody class="limiting">
                  <tr v-for="(item,i) in item.items" :key="i" class="drag-list">
                    <td
                      :style="{'color':item.s=='2'?'#595959':'','border-left':'1px solid #f5f5f5'}"
                    >{{i+1}}</td>
                    <td :style="{'color':item.s=='2'?'#595959':''}">
                      <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                    </td>
                    <td :style="{'color':item.s=='2'?'#595959':''}">
                      {{item.on}}
                      <i class="el-icon-arrow-right"></i>
                      {{item.tn}}
                    </td>
                    <td :style="{'color':item.s=='2'?'#595959':''}">
                      <div class="money">{{item.p}}</div>
                    </td>
                    <td :style="{'color':item.s=='2'?'#595959':''}">
                      <el-input v-model="item.pc" placeholder="请输入数量" class="alignment" />
                    </td>
                    <td :style="{'color':item.s=='2'?'#595959':''}">
                      <ellipsis-tooltip
                        :text="item.mn || '-----'"
                        class="one-txt-cut"
                        style="width:140px"
                      ></ellipsis-tooltip>
                    </td>
                    <td :style="{'color':item.s=='2'?'#595959':''}">{{item.pt}}</td>
                    <td :style="{'color':item.s=='2'?'#595959':''}">{{item.bt}}</td>
                    <td :style="{'color':item.s=='2'?'#595959':''}">{{item.s==1?'有效':'无效'}}</td>
                    <td style="color: #438dfd" @click="dpdeletereplace(j,i)">删除</td>
                  </tr>
                  <tr class="drag-list" v-if="item.items.length<1">
                    <td class="nodata" colspan="10" style="border-left: 1px solid #f5f5f5;">
                      <img src="../../../../assets/img/wu.png" alt />
                      <div class="hint">暂无数据</div>
                    </td>
                  </tr>
                  <tr class="drag-list" @click="additional(false,j)">
                    <td class="Theewitem" style="border-left: 1px solid #f5f5f5;">
                      <div>＋</div>
                      <div>添加单品</div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div class="setaddmeal" @click="addtitutiongroups">
              <div class="select">
                3&ensp;选 &ensp;
                <div>9999</div>
              </div>
              <table class="extend-unit">
                <thead class="mmodity">
                  <tr>
                    <th style="border-left: 1px solid #f5f5f5;">行号</th>
                    <th>单品名称</th>
                    <th>分类</th>
                    <th>单价</th>
                    <th class="tbdgf">
                      <span>数量</span>
                    </th>
                    <th>存货商品名</th>
                    <th>类型</th>
                    <th>营业类型</th>
                    <th>状态</th>
                    <th>操作</th>
                  </tr>
                </thead>
              </table>
              <div class="taddmeal">
                <span>＋</span> 新增替换组
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <table class="extend-unis">
                  <thead class="mmodity">
                    <tr>
                      <th>
                        <el-checkbox
                          :indeterminate="nature_isIndeterminate"
                          v-model="nature_checkAll"
                          @change="nature_handleCheckAllChange"
                        >行号</el-checkbox>
                      </th>
                      <th>区域名称</th>
                      <th>区域状态</th>
                    </tr>
                  </thead>
                  <tbody class="limiting">
                    <tr
                      v-for="(item,i) in regions"
                      :key="i"
                      class="drag-list"
                      :class="nature_checkedCities.includes(item.id)? 'drag-list-check':''"
                    >
                      <td>
                        <el-checkbox-group
                          v-model="nature_checkedCities"
                          @change="nature_handleCheckedCitiesChange"
                        >
                          <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                        </el-checkbox-group>
                      </td>
                      <td :style="{'color':item.s==1?'':'#595959'}">{{item.n}}</td>
                      <td :style="{'color':item.s==1?'':'#595959'}">{{item.s == 1?'有效':'无效'}}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </el-form>
          <span slot="footer" class="dialog-footer">
            <el-button @click="showOrHideDetailDialog" type="danger">删除</el-button>
            <el-button @click="newsetmeals = false">取消</el-button>
            <el-button type="primary" v-show="!singlecommodities" @click="saveitpackage">保存</el-button>
          </span>
        </el-dialog>
      </div>
      <!-- 新增套餐单品 -->
      <div class="newdefined" v-show="newexhibits">
        <el-dialog
          title="新增单品"
          @close="newexhibits = false"
          :visible.sync="newexhibits"
          :close-on-click-modal="false"
        >
          <div class="in_sum-rkrq">
            <div class="rkrq">
              <span>商品：</span>
              <el-cascader
                clearable
                :options="dcommoditytems"
                :props="optionProp"
                v-model="commoditycode"
                popper-class="liebdwd"
                ref="cascaderRef"
              ></el-cascader>
            </div>
            <div class="rkrq">
              <el-input v-model="get_set_items.name" placeholder="请输入商品名称 模糊查询"></el-input>
            </div>
            <div class="rkrq">
              <el-button type="primary" @click="gett_wwite">查询</el-button>
            </div>
          </div>
          <div style="display: inline-block;width: 602px; ">
            <table class="zhuixiaoi">
              <thead class="mmodity">
                <tr>
                  <th style="border-left:1px solid #f5f5f5">
                    <el-checkbox
                      v-model="checkedCitispesAll"
                      :indeterminate="isIndeterminateAll"
                      @change="changeCheckedCitispesAll"
                    >行号</el-checkbox>
                  </th>
                  <th>单品名称</th>
                  <th>分类</th>
                  <th>单价</th>
                  <!-- <th>数量</th> -->
                  <th>存货商品名</th>
                  <th>类型</th>
                  <th>营业类型</th>
                  <th>状态</th>
                </tr>
              </thead>
              <tbody class="limiting">
                <tr
                  v-for="(item,i) in ImportDatas"
                  :key="i"
                  class="drag-list"
                  draggable="true"
                  :class="checkedCitispes.includes(item.id)? 'drag-list-check':''"
                >
                  <td :style="{'border-left':'1px solid #f5f5f5','color':item.s=='2'?'#595959':''}">
                    <el-checkbox-group v-model="checkedCitispes" :disabled="item.control">
                      <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                    </el-checkbox-group>
                  </td>
                  <td :style="{'color':item.s=='2'?'#595959':''}">{{item.n}}</td>
                  <td :style="{'color':item.s=='2'?'#595959':''}">
                    {{item.on}}
                    <i class="el-icon-arrow-right"></i>
                    {{item.tn}}
                  </td>
                  <td :style="{'color':item.s=='2'?'#595959':''}">
                    <div class="money">{{item.p}}</div>
                  </td>
                  <!-- <td :style="{'color':item.s=='2'?'#595959':''}">{{item.pc}}</td> -->
                  <td
                    :style="{'color':item.s=='2'?'#595959':''}"
                    class="one-txt-cut"
                    style="width:140px"
                  >{{item.mn || '-----'}}</td>
                  <td :style="{'color':item.s=='2'?'#595959':''}">{{item.pt}}</td>
                  <td :style="{'color':item.s=='2'?'#595959':''}">{{item.bt}}</td>
                  <td :style="{'color':item.s=='2'?'#595959':''}">{{item.s==1?'有效':'无效'}}</td>
                </tr>
                <tr class="drag-list" v-if="ImportDatas.length<1">
                  <td class="nodata">
                    <img v-show="contcture ==1" src="../../../../assets/img/wu.png" alt />
                    <img v-show="contcture ==2" src="../../../../assets/img/空-请检索.png" alt />
                    <img v-show="contcture ==3" src="../../../../assets/img/加载中.png" alt />
                    <div v-show="contcture ==1" class="hint">暂无数据</div>
                    <div v-show="contcture ==2" class="hint">空-请检索</div>
                    <div v-show="contcture ==3" class="hint">加载中...</div>
                  </td>
                </tr>
                <infinite-loading
                  ref="infiniteLoading"
                  v-if="ImportDatas.length>0"
                  @infinite="infiniteHandler"
                  force-use-infinite-wrapper=".el-table__body-wrapper"
                >
                  <div class="loadmore" slot="spinner">加载中...</div>
                  <div class="loadmore" slot="no-more">没有更多数据</div>
                  <div class="loadmore" slot="no-results">没有更多数据</div>
                </infinite-loading>
              </tbody>
            </table>
          </div>
          <span slot="footer" class="dialog-footer">
            <el-button @click="newexhibits = false">取消</el-button>
            <el-button v-show="estimategdthz" type="primary" @click="setmealewproduct">新增</el-button>
            <el-button v-show="!estimategdthz" type="primary" @click="addchangeof">新增</el-button>
          </span>
        </el-dialog>
      </div>
      <!-- 是否强制创建套餐 -->
      <div class="deletealternative" v-show="deletealtative">
        <el-dialog
          title="新增套餐"
          @close="deletealtative = false"
          :visible.sync="deletealtative"
          :close-on-click-modal="false"
        >
          <div class="del">
            该套餐配置明细中, 存在无效单品。
            <br />如果强制新增, 该套餐会自动设置为
            <span>无效</span>状态（将来需
            <span>手动</span>设置该套餐为有效状态）, 是否强制新增该套餐?
          </div>
          <span slot="footer" class="dialog-footer">
            <el-button @click="deletealtative = false">取消</el-button>
            <el-button type="primary" @click="compellent">强制新增</el-button>
          </span>
        </el-dialog>
      </div>
      <!-- 创建套餐可点区域问题 -->
      <div class="Seternewdefed" v-show="Seterrortxsf">
        <el-dialog
          title="新增套餐错误"
          @close="Seterrortxsf = false"
          :visible.sync="Seterrortxsf"
          :close-on-click-modal="false"
        >
          <div class="ewdefed">{{Seterrorthree.msg}}</div>
          <div style="display: inline-block;">
            <table class="zhuixaoise">
              <thead class="mmodity">
                <tr>
                  <th style="border-left:1px solid #f5f5f5">行号</th>
                  <th>单品名称</th>
                  <th>分类</th>
                  <th>问题区域</th>
                </tr>
              </thead>
              <tbody class="limiting">
                <tr v-for="(item,i) in Seterrorthree.data" :key="i" class="drag-list">
                  <td :style="{'border-left':'1px solid #f5f5f5'}">{{i+1}}</td>
                  <td>{{item.n}}</td>
                  <td>
                    {{item.on}}
                    <i class="el-icon-arrow-right"></i>
                    {{item.tn}}
                  </td>
                  <td>
                    <div class="divbigesd" v-for="(ite,j) in item.r" :key="j">
                      <div class="data">{{ite}}</div>
                      <div v-if="j+1 != item.r.length" class="xian"></div>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <span slot="footer" class="dialog-footer">
            <el-button type="primary" @click="Seterrortxsf = false">确定</el-button>
          </span>
        </el-dialog>
      </div>

      <!-- 图片预览 -->
      <div class="imgDetails" v-show="imgDetails">
        <el-dialog
          title="图片预览"
          @close="imgDetails = false"
          :visible.sync="imgDetails"
          :close-on-click-modal="false"
        >
          <div style="height: 100%;margin-top:30px">
            <h3 class="m-b-6">当前商品小程序预览</h3>
            <div v-for="item in 6" :key="item" style="width:300px;height:120px;background:#1B1B1E;margin-left:100px" layout="row" layout-align="space-between center">
              <div style="width:100px;height:100px;text-align:center">
                <img
                v-if="imgDetails"
                class="prdImgLoadImg"
                @load="prdImgLoadHandle"
                style="width:90px;height:90px"
                :src="`${http}${QuantityProduction?newmerchandise.pic_url:setmeals.pic_url}`"
                alt
                />
              </div>
              
              <div style="width:190px;height:100px;border-bottom:1px solid #333;padding-right:10px;box-sizing:border-box" layout="column" layout-align="space-between start">
                <p class="white">{{QuantityProduction?newmerchandise.name:setmeals.name}}</p>
                <div style="width:100%" layout="row" layout-align="space-between center">
                  <div style="color:#1EDAAD;font-size:0">
                    <span style="font-size:12px;margin-right:2px">¥</span>
                    <span style="font-size:16px">{{QuantityProduction?newmerchandise.price:setmeals.price}}</span>
                  </div>
                  <div>
                    <img style="width:22px;height:22px;" :src="require('@/assets/mgr-img/add.png')" />
                  </div>
                </div>
              </div>
            </div>
          </div>
          <span slot="footer" class="dialog-footer">
            <el-button @click="imgDetails = false">关闭</el-button>
          </span>
        </el-dialog>
      </div>

      <!-- 无效有效删除 -->
      <div v-show="dialogFible" class="diagrgeesfelogFor">
        <el-dialog
          :title="srnr"
          :visible.sync="dialogFible"
          @close="dialogFible = false"
          :close-on-click-modal="false"
          width="50%"
        >
          <div style="color:red;line-height:40px" v-show="cwsm.ns.length>0">以下对象存在依赖，需人工处理依赖</div>
          <div v-show="cwsm.ns.length>0">
            <table style="width:100%">
              <thead >
                <tr>
                  <th style="width:30%;line-height:30px;text-align:center">序号</th>
                  <th style="width:70%;line-height:30px;text-align:center">说明</th>
                </tr>
              </thead>
              <tbody :style="{'width':cwsm.ns.length>6?'calc(100% + 6px)':'100%'}">
                <tr v-for="(item,i) in cwsm.ns" :key="i" >
                  <td style="width:30%;line-height:30px;text-align:center">{{i+1}}</td>
                  <td style="width:70%;line-height:30px;text-align:center">{{item || '-----'}}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <span slot="footer" class="dialog-footer">
            <el-button @click="dialogFible = false">关闭</el-button>
          </span>
        </el-dialog>
      </div>

      <!-- 删除确认框 -->
      <el-dialog title="确认删除" :visible.sync="dialogDelVisible" width="30%" :before-close="showOrHideDetailDialog">
        <p style="line-height:40px">确认删除此商品信息？</p>
        <span slot="footer" class="dialog-footer">
          <el-button @click="showOrHideDetailDialog">取 消</el-button>
          <el-button type="primary" @click="deleteSureHandle">确 定</el-button>
        </span>
      </el-dialog>
    </div>
  </div>
</template>
<script>
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import InfiniteLoading from "vue-infinite-loading";
import { sessionStorage, localStorage } from '@/utils/common/storage'
import eventVue from '@/utils/eventVue';

export default {
  data() {
    return {
      http: '',
      nr: "", // 搜索内容
      stairNames: "", // 全部
      secondNames: "", // 一级级分类id
      materialNames: "", // 二级分类id
      classifys: [], //一级二级分类数据

      gaibland: "", //选中哪一个状态

      searchesult: {
        yij: [],
        erj: [],
        wl: [],
        sl: ""
      }, //模糊查询结果
      sfshow: true, //是否查询
      wuliaoid: "", //商品id

      ERPcommodity: false, //控制ERP商品弹窗
      dept_items: [], //ERP商品信息
      optionProps: {
        value: "id",
        label: "n",
        children: "subs",
        checkStrictly: true,
        expandTrigger: "hover"
      }, //规则
      erp_prds: {
        page_num: 1, //第几页
        page_size: 6, //每页行数
        is_init: 1, //页面初始化
        erp_cate_code: "", //erp商品分类编码
        name: "", //erp商品名称 模糊查询
        pagecnt: 1, //总页数
        rowcnt: 1 //总行数
      },
      dept_code: [], //商品分类树
      erps_prdss: [], //erp商品数据
      checkedCitispesAll: false, // 全选
      isIndeterminateAll: false, // 半全选
      checkedCitispes: [], //已选择内容

      List: [], //全部内容
      checkAll: false, //全部选中触发
      checkedCities: [], //已选择内容
      isIndeterminate: false, //全选或者全不选

      mklibs: [], //出品库
      regions: [], //区域
      nature_isIndeterminate: false, // 区域全选或者全不选
      nature_checkAll: false, //区域全部选中触发
      nature_checkedCities: [], //区域已选择内容

      pdddymy: false, //判断有没有二级分类
      merchandise: [], //商品
      QuantityProduction: false, //控制新增商品的打开关闭
      newmerchandise: {
        name: "", //商品名称
        phoneticize: "", //拼音
        English: "", //英文名
        price: "", //单价
        marketprices: false, //根据商品类型改变
        SKUtype: "", //商品类型
        businesstype: "", //营业类型
        usedSubCheckboxVal: false, // 是否仅用于优惠
        forbidden: false, // 禁用
        inventory: [], //存货商品
        Inventorygoods: true, //存货商品是否显示
        pic_url: "" //商品图片
      }, //新建商品
      singlecommodities: true, // 判断单品是编辑还是新增

      setmeals: {
        name: "", //商品名称
        phoneticize: "", //拼音
        English: "", //英文名
        price: "", //单价
        businesstype: "1", // 营业类型
        usedSubCheckboxVal: false, // 是否仅用于优惠
        one_cate_id: 0, //一级id
        two_cate_id: 0, //二级id
        is_force: 2, //是否强制添加, 1 强制添加 2  普通模式添加
        pic_url: "" //商品图片
      }, //套餐
      newsetmeals: false, //控制新增套餐
      setmeallist: [], //套餐列表
      newexhibits: false, //控制新增单品
      get_set_items: {
        name: "",
        page_num: 1, //第几页
        page_size: 6, //每页行数
        is_init: 1
      },
      ImportDatas: [], //无限加载列表内容
      dcommoditytems: [], //单品信息
      optionProp: {
        value: "id",
        label: "n",
        children: "ss",
        checkStrictly: true,
        expandTrigger: "hover"
      }, //规则
      commoditycode: [], //单品分类树

      substitute: [], //替换组
      estimategdthz: true, //判断是固定单品还是替换组添加
      Whichoneadd: 0, //判断添加到哪里
      substijige: 0, //删除第几个替换组
      deletealtative: false, //判断是否强制创建套餐
      Seterrorthree: {}, //套餐错误3返回列表
      Seterrortxsf: false, //判断套餐错误3列表是否显示

      invalidree: {}, //置为无效时错误2返回列表
      invalidive: false, //判断是否显示错误列表
      scwxvalidive: true, // 判断是删除还是置为无效文案

      Productibrary: {}, //置为有效时错误3 4返回列表
      roductibrive: false, //判断是否显示错误列表
      pandsansi: true, //判断是错误3还是4

      controlpicture: "2", // erp搜索商品
      contcture: "2", //搜索单品

      one_cate_name: "", //一级分类名称
      two_cate_name: "", //二级分类名称
      one_cate_id: "", //一级分类id
      two_cate_id: "", //二级分类id

      windowWidt: document.documentElement.clientWidth, //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight, //实时屏幕高度
      MaxHeight: 0, //滚动高度

      form_rules: ["name", "English"],
      form_rules_tc: ["tc_name", "tc_English"],
      form_rule_msg_name: "",
      form_rule_msg_English: "",

      imgDetails: false, //图片预览

      
      dialogDelVisible: false,  // 是否显示删除确认框      
      
      dialogFible: false, //控制错误2是否显示
      srnr: "", //文案
      cwsm: {
        ns: [], //不可操作列表
        cs: [] //可一键操作列表
      }, //错误2说明
    };
  },
  mounted() {
    this.$root.$on('next', () => { 
      this.demand() // 调用父路由中的方法
    })
    this.demand();
    if (localStorage.getItem("openstair") == "") {
      this.stairNames = "";
    } else {
      this.stairNames = localStorage.getItem("openstair");
    }
    if (localStorage.getItem("opentwo") == "") {
      this.secondNames = "";
    } else {
      this.secondNames = localStorage.getItem("opentwo");
    }

    this.RollMaxHeight(this.windowHeigh);
    var that = this;
    window.onresize = () => {
      return (() => {
        window.fullHeight = document.documentElement.clientHeight;
        window.fullWidth = document.documentElement.clientWidth;
        that.windowHeigh = window.fullHeight; // 高
        that.windowWidt = window.fullWidth; // 宽
      })();
    };
    eventVue.$on('reloadCategoryList', () => {
      this.demand()
    })
  },
  components: {
    EllipsisTooltip,
    IconButton,
    InfiniteLoading
  },

  methods: {
    delImg() {
      if (this.QuantityProduction) {
        this.$refs.uploadPicUrlP.clearFiles();
        this.newmerchandise.pic_url = "";
      } else {
        this.$refs.uploadPicUrlT.clearFiles();
        this.setmeals.pic_url = "";
      }
    },
    uploadRequest(params) {
      if (!params.file) return;
      console.log(params.file);
      this.$api.BMS.Prd.requestOssPt().then(item => {
        let res = item.data,
          src =
            this.$overall.generateUUID() + "." + params.file.name.split(".")[1],
          key = res.dir + src;
          this.http = res.host + '/' + res.dir
        this.$api.BMS.Prd.handleUploadFile(
          res.host,
          {
            key: key,
            policy: res.policy,
            OSSAccessKeyId: res.accessid,
            success_action_status: "200", //让服务端返回200,不然，默认会返回204
            signature: res.signature
          },
          params.file
        ).then(data => {
          if (this.QuantityProduction) {
            console.log(111);
            this.newmerchandise.pic_url = src;
          } else {
            console.log(222);
            this.setmeals.pic_url = src;
          }
        });
      });
    },
    // form表单检测
    validator(val) {
      switch (val) {
        case "name":
          if (this.newmerchandise.name == "") {
            this.form_rule_msg_name = "请输入商品名称";
          } else if (this.$overall.character(this.newmerchandise.name) > 60) {
            this.form_rule_msg_name = "输入文字长度超过30";
          } else {
            this.form_rule_msg_name = "";
          }
          break;
        case "English":
          if (this.$overall.character(this.newmerchandise.English) > 60) {
            this.form_rule_msg_English = "输入文字长度超过30";
          } else {
            this.form_rule_msg_English = "";
          }
          break;
        case "tc_name":
          if (this.setmeals.name == "") {
            this.form_rule_msg_name = "请输入套餐名称";
          } else if (this.$overall.character(this.setmeals.name) > 60) {
            this.form_rule_msg_name = "输入文字长度超过30";
          } else {
            this.form_rule_msg_name = "";
          }
          break;
        case "tc_English":
          if (this.$overall.character(this.setmeals.English) > 60) {
            this.form_rule_msg_English = "输入文字长度超过30";
          } else {
            this.form_rule_msg_English = "";
          }
          break;
      }
    },
    // 请求数据
    demand() {
      this.$api.BMS.Prd.requestprdcatetree().then(res => {
        if (res.code == 1) {
          this.classifys = res.data || [];
          this.$forceUpdate()
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 请求商品一级分类数据
    stairhandleChange(val) {
      localStorage.setItem("openstair", val);
      if (val == "") {
        this.secondNames = "";
        localStorage.setItem("opentwo", "");
      } else {
        if (this.secondNames == "") {
          this.materialNames = "";
          localStorage.setItem("openthree", "");
        }
      }
    },
    // 请求二级分类数据 获取一级分类id
    secondhandleChange(val) {
      localStorage.setItem("opentwo", val);
      if (val == "") {
        this.materialNames = "";
        localStorage.setItem("openthree", "");
      }
    },
    // 请求商品数据  获取二级分类id
    materialhandleChange(val) {
      this.materialNames = val;
      localStorage.setItem("openthree", val);
    },
    // 给二级分类添加一级分类id
    tjflyj() {
      for (const key in this.searchesult.erj) {
        for (const iterator of this.classifys) {
          for (const terat in iterator.subs) {
            if (this.searchesult.erj[key].id == iterator.subs[terat].id) {
              this.searchesult.erj[key].yij = iterator.id;
            }
          }
        }
      }
    },
    // 查询选择 一级
    xuanzyij(id) {
      this.nr = "";
      this.sfshow = true;
      this.stairNames = "全部";
      this.secondNames = id;
      this.materialNames = "";
      this.$router.push(`/BMS/Prds/tcate/${id}`);
    },
    // 查询选择 二级
    xuanzerj(id, yij) {
      console.log(id, yij);
      this.nr = "";
      this.sfshow = true;
      this.stairNames = "全部";
      this.secondNames = yij;
      this.materialNames = id;
      this.$router.push(`/BMS/Prds/Prd/${id}`);
    },
    // 查询选择 商品
    xuanzwl(stair) {
      console.log(stair);
      this.checkedCities = [stair.id];
      if (+stair.t === 4) {
        this.Editpackage();
      } else {
        this.Commoditiesditor();
      }
    },

    // 请求数据
    demandRegions(callback) {
      console.log("this.one_cate_id", this.one_cate_id);
      this.$api.BMS.Prd.requestprdass_items().then(res => {
        if (res.code == 1) {
          console.log(res.data.regions);
          let fmk = "";
          res.data.cates.map(item => {
            if (item.id == this.one_cate_id) {
              fmk = item.fmk;
            }
          });
          if (res.data.regions) {
            for (const key in res.data.regions) {
              res.data.regions[key].fmk = fmk;
              if (res.data.regions[key].s == 1) {
                res.data.regions[key].mklibs = [];
                for (const iterator of res.data.mklibs || []) {
                  if (iterator.s == 1) {
                    res.data.regions[key].mklibs.push(iterator);
                  }
                }
              } else {
                res.data.regions[key].mklibs = res.data.mklibs || [];
              }
            }
          }
          this.regions = res.data.regions || [];
          callback && callback();
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 记录初始信息
    dragstart(item) {
      this.oldItem = item;
    },
    // 记录过程中信息
    dragenter(item) {
      this.newItem = item;
    },
    // 做最终操作
    dragend(item) {
      if (this.oldItem != this.newItem) {
        let oldIndex = this.merchandise.indexOf(this.oldItem);
        let newIndex = this.merchandise.indexOf(this.newItem);
        console.log(oldIndex);
        console.log(newIndex);
        var down_up = 1;
        if (oldIndex > newIndex) {
          down_up = 2;
        } else if (oldIndex < newIndex) {
          down_up = 1;
        }
        this.$api.BMS.Prd.requestprdmove_dsp({
          id: this.oldItem.id,
          dest_id: this.newItem.id,
          down_up: down_up
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "更改位置成功",
              type: "success",
              duration: 1000
            });
            let newList = [...this.merchandise]; // 中间数组，用于交换两个节点
            // 删除老的节点
            newList.splice(oldIndex, 1);
            // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.oldItem);
            // 更新this.List，触发transition-group的动画效果
            this.merchandise = [...newList];
          } else {
            this.$message.warning(res.msg);
          }
        });
      }
    },
    // 控制全选或者全不选
    handleCheckAllChange(val) {
      console.log(this.merchandise);
      console.log(val);
      if (val) {
        // console.log(this.merchandise);
        this.checkedCities = [];
        for (const key in this.merchandise) {
          this.checkedCities.push(this.merchandise[key].id);
        }
      } else {
        this.checkedCities = [];
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.merchandise.length;
      this.isIndeterminate =
        checkedCount > 0 && checkedCount < this.merchandise.length;
      // console.log(this.checkedCities);
    },
    // 商品单位控制全选或者全不选
    nature_handleCheckAllChange(val) {
      if (val) {
        this.nature_checkedCities = [];
        for (const key in this.regions) {
          this.nature_checkedCities.push(this.regions[key].id);
        }
      } else {
        this.nature_checkedCities = [];
      }
      this.nature_isIndeterminate = false;
    },
    // 商品单位控制单个选中
    nature_handleCheckedCitiesChange(value) {
      // console.log(value);
      let checkedCount = value.length;
      this.nature_checkAll = checkedCount === this.regions.length;
      this.nature_isIndeterminate =
        checkedCount > 0 && checkedCount < this.regions.length;
    },
    // 打开绑定
    binding() {
      this.controlpicture = "2";
      this.dept_code = []; //商品分类树
      this.erps_prdss = []; //erp商品数据
      this.erp_prds = {
        page_num: 1, //第几页
        page_size: 6, //每页行数
        is_init: 1, //页面初始化
        erp_cate_code: "", //erp商品分类编码
        name: "", //erp商品名称 模糊查询
        pagecnt: 1, //总页数
        rowcnt: 1 //总行数
      };

      this.ERPcommodity = true;
      this.prderp_prds();
    },
    // 读取erp商品
    prderp_prds() {
      this.controlpicture = "3";
      this.erps_prdss = [];
      setTimeout(() => {
        this.$api.BMS.Prd.requestprderp_prds({
          page_num: this.erp_prds.page_num,
          page_size: this.erp_prds.page_size,
          is_init: this.erp_prds.is_init,
          erp_cate_id: this.erp_prds.erp_cate_code,
          name: this.erp_prds.name
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            if (res.data.erp_prds == null) {
              this.controlpicture = "1";
            }
            this.dept_items = res.data.erp_cates || [];
            this.erps_prdss = res.data.erp_prds || [];
            this.page_num = res.data.page_num;
            this.pagecnt = res.data.page_cnt;
            this.rowcnt = res.data.row_cnt;
          } else {
            this.$message.warning(res.msg);
          }
        });
      }, 1000);
    },
    // 绑定
    bindingERp() {
      console.log(this.checkedCitispes);
      console.log(this.erps_prdss);
      if (this.checkedCitispes.length > 0) {
        const inventory = [];
        this.checkedCitispes.forEach(el => {
          const find = this.erps_prdss.find(item => item.id == el);
          if (find) inventory.push(find);
        });
        this.newmerchandise.inventory = inventory;
        this.ERPcommodity = false;
      } else {
        this.$message.warning("绑定商品不能为空");
      }
    },
    // 当前是多少页
    handleCurrentChange(val) {
      console.log(`当前页: ${val}`);
      this.erp_prds.page_num = val;
      this.prderp_prds();
    },
    // 判断打开单品还是套餐编辑
    staircompile() {
      this.form_rule_msg_name = "";
      this.form_rule_msg_English = "";
      if (this.checkedCities.length == 1) {
        for (const key in this.merchandise) {
          if (this.checkedCities[0] == this.merchandise[key].id) {
            console.log(this.merchandise[key].pt);
            if (this.merchandise[key].pt == "套餐") {
              this.Editpackage();
            } else {
              this.Commoditiesditor();
            }
          }
        }
      } else {
        this.$message({
          message: "请选择一个进行编辑",
          type: "warning"
        });
      }
    },
    // 打开单品编辑
    Commoditiesditor() {
      let that = this;
      this.$api.BMS.Prd.requestprdget({ id: this.checkedCities[0] }).then(
        res => {
          this.singlecommodities = false;
          this.one_cate_id = res.data.prd.one_cate_id;
          this.one_cate_name = res.data.prd.one_cate_name;
          this.two_cate_id = res.data.prd.two_cate_id;
          this.two_cate_name = res.data.prd.two_cate_name;
          this.newmerchandise = {
            name: res.data.prd.name,
            phoneticize: res.data.prd.name_py,
            English: res.data.prd.name_eng,
            businesstype: res.data.prd.biz_type + "",
            usedSubCheckboxVal: res.data.prd.use_type == 2, 
            inventory: res.data.prd.m_id
              ? [
                  {
                    id: res.data.prd.m_id,
                    n: res.data.prd.m_name,
                    un: res.data.prd.m_uint_name
                  }
                ]
              : [],
            marketprices: this.newmerchandise.marketprices,
            forbidden: this.newmerchandise.forbidden,
            Inventorygoods: this.newmerchandise.Inventorygoods,
            price: res.data.prd.price + "",
            pic_url: res.data.prd.pic_name + "",
            SKUtype: res.data.prd.prd_type + ""
          };
          this.http = res.data.prd.pic_prefix || ''

          this.QuantityProduction = true;
          res.data.region_prds = res.data.region_prds || []
          
          
            this.demandRegions(() => {
              that.regions.map(v => {
                that.nature_checkedCities = [];
                res.data.region_prds.map(item => {
                  that.nature_checkedCities.push(item.rid);
                  if (v.id == item.rid) {
                    v.fmk = item.mid;
                  }
                });
              });
              if(res.data.region_prds.length == 0) {
                // 其配置区域  出品库
                this.nature_checkAll = false
                this.nature_isIndeterminate = false
              } else if (that.regions.length == res.data.region_prds.length) {
                that.nature_checkAll = true;
              } else if (that.regions.length > res.data.region_prds.length) {
                that.nature_isIndeterminate = true;
              }
            });
        }
      );
    },
    // 保存编辑商品
    savecommodity() {
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name || this.form_rule_msg_English) return;
      var s = [];
      var w = [];
      for (const key in this.regions) {
        for (const ke in this.nature_checkedCities) {
          if (this.regions[key].id == this.nature_checkedCities[ke]) {
            s.push(this.regions[key].id);
            w.push(this.regions[key].fmk);
          }
        }
      }
      if (
        this.newmerchandise.SKUtype != 1 &&
        this.newmerchandise.SKUtype != 3
      ) {
        this.newmerchandise.inventory = [];
      }
      this.$api.BMS.Prd.requestprdsave({
        id: this.checkedCities[0],
        name: this.newmerchandise.name,
        one_cate_id: this.one_cate_id,
        two_cate_id: this.two_cate_id,
        name_eng: this.newmerchandise.English,
        name_py: this.newmerchandise.phoneticize,
        pic_name: this.newmerchandise.pic_url,
        price:
          this.newmerchandise.price == "时价" ? "0" : this.newmerchandise.price,
        prd_type: Number(this.newmerchandise.SKUtype),
        biz_type: Number(this.newmerchandise.businesstype),
        use_type: this.newmerchandise.usedSubCheckboxVal ? 2 : 1,  // 用途限制 1 不限 2 仅用于优惠
        regions: s,
        mklibs: w,
        mat_id:
          this.newmerchandise.inventory.length == 0
            ? 0
            : this.newmerchandise.inventory[0].id // int64  关联的存货商品Id
      }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.QuantityProduction = false;
          this.$message({
            showClose: true,
            message: "操作成功",
            type: "success"
          });
        } else {
          this.$message({ message: res.msg, type: "error" });
        }
      });
    },
    // 打开新增套餐
    newsetmeal() {
      this.form_rule_msg_name = "";
      this.form_rule_msg_English = "";
      if (this.pdddymy) {
        this.singlecommodities = true;
        this.newsetmeals = true;
        this.setmeallist = [];
        this.demandRegions();
        this.setmeals = {
          id: "",
          name: "", //商品名称
          phoneticize: "", //拼音
          English: "", //英文名
          price: "", //单价
          one_cate_id: 0, //一级id
          two_cate_id: 0, //二级id
          is_force: 2
        }; //套餐
        this.substitute = [];
        this.nature_isIndeterminate = false;
        this.nature_checkAll = false;
        this.nature_checkedCities = [];
        for (const key in this.regions) {
          this.nature_checkedCities.push(this.regions[key].id);
        }
        console.log(this.regions);
        if (this.nature_checkedCities.length > 0) {
          this.nature_checkAll = true;
        }

        this.$nextTick(() => {
          //次要代码
          this.$refs.xidhf.focus();
        });
      } else {
        this.$message({
          showClose: true,
          message: "没有二级分类，请先创建二级分类",
          type: "warning"
        });
      }
    },
    // 套餐新增单品
    additional(judge, index) {
      this.contcture = "2";
      this.ImportDatas = [];
      this.estimategdthz = judge;
      if (!judge) {
        this.Whichoneadd = index;
      }
      this.get_set_items.name = "";
      this.get_set_items.page_num = 1;
      this.get_set_items.is_init = 1;
      this.setmeals.one_cate_id = 0;
      this.setmeals.two_cate_id = 0;
      this.commoditycode = [];
      this.newexhibits = true;
      this.checkedCitispes = [];
      this.$api.BMS.Prd.requestprdget_set_items({
        name: this.get_set_items.name,
        page_num: this.get_set_items.page_num,
        page_size: this.get_set_items.page_size,
        is_init: this.get_set_items.is_init,
        one_cate_id: this.setmeals.one_cate_id,
        two_cate_id: this.setmeals.two_cate_id
      }).then(res => {
        // console.log(res);
        if (res.code == 1) {
          this.dcommoditytems = res.data.cates || [];
          if (res.data.items) {
            // console.log(res.data.items);
            // console.log(this.setmeallist);
            console.log(judge);
            if (judge) {
              for (const key in res.data.items) {
                for (const i in this.setmeallist) {
                  if (res.data.items[key].id == this.setmeallist[i].id) {
                    res.data.items[key].control = true;
                    console.log(res.data.items[key]);
                  }
                }
              }
            } else {
              for (const key in res.data.items) {
                for (const i in this.substitute[index].items) {
                  if (
                    res.data.items[key].id == this.substitute[index].items[i].id
                  ) {
                    res.data.items[key].control = true;
                    console.log(res.data.items[key]);
                  }
                }
              }
            }
          }
          // this.ImportDatas = res.data.items || []
          if (this.$refs.infiniteLoading) {
            this.$refs.infiniteLoading.$emit("$InfiniteLoading:reset");
          }
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 查询
    gett_wwite() {
      this.contcture = "3";
      this.ImportDatas = [];
      setTimeout(() => {
        this.get_set_items.is_init = 2;
        this.get_set_items.page_num = 1;
        this.$api.BMS.Prd.requestprdget_set_items({
          name: this.get_set_items.name,
          page_num: this.get_set_items.page_num,
          page_size: this.get_set_items.page_size,
          is_init: this.get_set_items.is_init,
          one_cate_id: this.setmeals.one_cate_id,
          two_cate_id: this.setmeals.two_cate_id
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            if (res.data.items == null) {
              this.contcture = "1";
            }
            this.checkedCitispesAll = false;
            this.isIndeterminateAll = false;
            this.ImportDatas = res.data.items || [];
            if (this.$refs.infiniteLoading) {
              this.$refs.infiniteLoading.$emit("$InfiniteLoading:reset");
            }
            if (res.data.items) {
              if (this.estimategdthz) {
                for (const key in res.data.items) {
                  for (const i in this.setmeallist) {
                    if (res.data.items[key].id == this.setmeallist[i].id) {
                      res.data.items[key].control = true;
                    }
                  }
                }
              } else {
                for (const key in res.data.items) {
                  for (const i in this.substitute[this.Whichoneadd].items) {
                    if (
                      res.data.items[key].id ==
                      this.substitute[this.Whichoneadd].items[i].id
                    ) {
                      res.data.items[key].control = true;
                    }
                  }
                }
              }
            }
          } else {
            this.$message.warning(res.msg);
          }
        });
      }, 1000);
    },
    // 无线加载
    infiniteHandler($state) {
      // 这里模仿加载延迟1秒钟
      setTimeout(() => {
        console.log("延迟");
        this.get_set_items.page_num++;
        this.$api.BMS.Prd.requestprdget_set_items({
          name: this.get_set_items.name,
          page_num: this.get_set_items.page_num,
          page_size: this.get_set_items.page_size,
          is_init: 2,
          one_cate_id: this.setmeals.one_cate_id,
          two_cate_id: this.setmeals.two_cate_id
        }).then(res => {
          // console.log(res);
          if (res.code == 1) {
            if (res.data.items) {
              if (this.estimategdthz) {
                for (const key in res.data.items) {
                  for (const i in this.setmeallist) {
                    if (res.data.items[key].id == this.setmeallist[i].id) {
                      res.data.items[key].control = true;
                    }
                  }
                  this.ImportDatas.push(res.data.items[key]);
                }
              } else {
                for (const key in res.data.items) {
                  for (const i in this.substitute[this.Whichoneadd].items) {
                    if (
                      res.data.items[key].id ==
                      this.substitute[this.Whichoneadd].items[i].id
                    ) {
                      res.data.items[key].control = true;
                    }
                  }
                  this.ImportDatas.push(res.data.items[key]);
                }
              }
              // for (const iterator of res.data.items) {
              //     this.ImportDatas.push(iterator)
              // }
              $state.loaded();
            } else {
              $state.complete();
            }
          } else {
            this.get_set_items.page_num = this.get_set_items.page_num - 1;
            this.$message({ message: res.msg, type: "error" });
          }
        });
      }, 1000);
    },
    // 套餐新增固定单品
    setmealewproduct() {
      if (this.checkedCitispes.length > 0) {
        for (const iterator of this.checkedCitispes) {
          for (const i in this.ImportDatas) {
            if (this.ImportDatas[i].id == iterator) {
              this.setmeallist.push(this.ImportDatas[i]);
            }
          }
        }
        this.newexhibits = false;
        console.log(this.setmeallist);
      } else {
        this.$message.warning("请选中一个进行添加");
      }
    },
    // 套餐单品删除
    dpdelete(i) {
      this.setmeallist.splice(i, 1);
    },
    // 新增替换组
    addtitutiongroups() {
      this.substitute.push({
        sel_cnt: "",
        items: [],
        deletejudge: false
      });
      this.$nextTick(() => {
        //次要代码
        var container = this.$refs.rollbott.$el;
        container.scrollTop = container.scrollHeight;
      });
    },
    // 给套餐通替换组添加单品
    addchangeof() {
      if (this.checkedCitispes.length > 0) {
        for (const iterator of this.checkedCitispes) {
          for (const i in this.ImportDatas) {
            if (this.ImportDatas[i].id == iterator) {
              this.substitute[this.Whichoneadd].items.push(this.ImportDatas[i]);
            }
          }
        }
        this.newexhibits = false;
      } else {
        this.$message.warning("请选中一个进行添加");
      }
    },
    // 删除替换组单品
    dpdeletereplace(j, i) {
      this.substitute[j].items.splice(i, 1);
    },
    // 删除替换组
    deletereplace(i) {
      this.substitute.splice(i, 1);
    },
    // 强制添加
    compellent() {
      this.deletealtative = false;
      this.setmeals.is_force = 1;
      this.addsetmeal();
    },
    // 新增套餐
    addsetmeal() {
      this.form_rules_tc.map(item => this.validator(item));
      if (this.form_rule_msg_name || this.form_rule_msg_English) return;
      // if (this.setmeallist.length == 0) {
      //   this.$message({ message: "请添加单品信息", type: "error" });
      // } else {
        console.log(this.setmeallist);
        var fix_items = [];
        var rpl_items = [];
        for (const key in this.setmeallist) {
          fix_items.push({
            pid: this.setmeallist[key].id,
            pc: Number(this.setmeallist[key].pc ? this.setmeallist[key].pc : 1)
          });
        }
        for (const key in this.substitute) {
          if (this.substitute[key].items.length > 0) {
            var items = [];
            for (const ky in this.substitute[key].items) {
              items.push({
                pid: this.substitute[key].items[ky].id,
                pc: Number(
                  this.substitute[key].items[ky].pc
                    ? this.substitute[key].items[ky].pc
                    : 1
                )
              });
            }
            rpl_items.push({
              sel_cnt: Number(this.substitute[key].sel_cnt),
              items: items
            });
          }
        }
        var region_ids = [];
        for (const key in this.regions) {
          for (const ke in this.nature_checkedCities) {
            if (this.regions[key].id == this.nature_checkedCities[ke]) {
              region_ids.push(this.regions[key].id);
            }
          }
        }
        this.$api.BMS.Prd.requestprdnew_set({
          name: this.setmeals.name,
          one_cate_id: this.classify.stairSecond[this.classify.stairfl].id,
          two_cate_id: this.classify.stairSecond[this.classify.stairfl].ss[
            this.classify.Secondfl
          ].id,
          name_eng: this.setmeals.English,
          name_py: this.setmeals.phoneticize,
          price: this.setmeals.price,
          biz_type: this.setmeals.businesstype * 1,
          pic_name: this.setmeallist.pic_url,
          is_force: Number(this.setmeals.is_force),
          fix_items: fix_items,
          rpl_items: rpl_items,
          region_ids: region_ids
        }).then(res => {
          console.log(res);
          if (res.code == 1 || res.code == 6) {
            this.newsetmeals = false;
            if (res.msg === '') {
              this.$message({
                showClose: true,
                message: "操作成功",
                type: 'success'
              })
            } else {
              this.$message({
                showClose: true,
                message: res.msg,
                type: 'warning'
              })
            }
            this.refresh(
              this.classify.stairSecond[this.classify.stairfl].ss[
                this.classify.Secondfl
              ].id
            );
          } else if (res.code == 2) {
            this.deletealtative = true;
          } else if (res.code == 3) {
            this.Seterrortxsf = true;
            this.Seterrorthree = {
              data: res.data,
              msg: res.msg
            };
          } else {
            this.$message.warning(res.msg);
          }
        });
      // }
    },
    // 编辑套餐
    Editpackage() {
      let that = this;
      this.$api.BMS.Prd.requestprdget_set({ id: this.checkedCities[0] }).then(
        res => {
          console.log(res);
          if (res.code == 1) {
            this.one_cate_id = res.data.one_cate_id;
            this.one_cate_name = res.data.one_cate_name;
            this.two_cate_id = res.data.two_cate_id;
            this.two_cate_name = res.data.two_cate_name;
            this.setmeals = {
              id: res.data.id,
              name: res.data.name,
              one_cate_id: res.data.one_cate_id,
              two_cate_id: res.data.two_cate_id,
              phoneticize: res.data.name_py || "",
              English: res.data.name_eng || "",
              price: res.data.price,
              businesstype: res.data.biz_type.toString() || "",
              usedSubCheckboxVal: res.data.ut == 2,
              pic_url: res.data.pic_name,
              is_force: 2 //是否强制添加, 1 强制添加 2  普通模式添加
            };
            this.http = res.data.pic_prefix || ''
            this.setmeallist = res.data.fix_items || [];
            this.nature_checkedCities = res.data.sel_region_ids || [];
            this.demandRegions(() => {
              if (res.data.sel_region_ids.length == 0) {
                that.nature_isIndeterminate = false;
                that.nature_checkAll = false;
              } else if (
                that.regions.length == res.data.sel_region_ids.length
              ) {
                that.nature_checkAll = true;
              } else {
                that.nature_isIndeterminate = true;
              }
            });
            this.substitute = [];
            for (const key of res.data.rpl_items || []) {
              this.substitute.push({
                sel_cnt: key.sel_cnt,
                items: key.items,
                deletejudge: false
              });
            }

            this.singlecommodities = false;
            this.newsetmeals = true;
          } else {
            this.$message.warning(res.msg);
          }
        }
      );
    },
    // 保存编辑套餐
    saveitpackage() {
      this.form_rules_tc.map(item => this.validator(item));
      if (this.form_rule_msg_name || this.form_rule_msg_English) return;
      // if (this.setmeallist.length == 0) {
      //   this.$message({ message: "请添加单品信息", type: "error" });
      // } else {
        console.log(this.setmeallist);
        var fix_items = [];
        var rpl_items = [];
        for (const key in this.setmeallist) {
          fix_items.push({
            pid: this.setmeallist[key].id,
            pc: Number(this.setmeallist[key].pc ? this.setmeallist[key].pc : 1)
          });
        }
        for (const key in this.substitute) {
          if (this.substitute[key].items.length > 0) {
            var items = [];
            for (const ky in this.substitute[key].items) {
              items.push({
                pid: this.substitute[key].items[ky].id,
                pc: Number(
                  this.substitute[key].items[ky].pc
                    ? this.substitute[key].items[ky].pc
                    : 1
                )
              });
            }
            rpl_items.push({
              sel_cnt: Number(this.substitute[key].sel_cnt),
              items: items
            });
          }
        }
        var region_ids = [];
        for (const key in this.regions) {
          for (const ke in this.nature_checkedCities) {
            if (this.regions[key].id == this.nature_checkedCities[ke]) {
              region_ids.push(this.regions[key].id);
            }
          }
        }
        this.$api.BMS.Prd.requestprdsave_set({
          id: this.setmeals.id,
          name: this.setmeals.name,
          one_cate_id: this.one_cate_id,
          two_cate_id: this.two_cate_id,
          name_eng: this.setmeals.English,
          name_py: this.setmeals.phoneticize,
          pic_name: this.setmeals.pic_url,
          price: this.setmeals.price,
          biz_type: this.setmeals.businesstype * 1,
          use_type: this.setmeals.usedSubCheckboxVal ? 2 : 1,
          is_force: Number(this.setmeals.is_force),
          fix_items: fix_items,
          rpl_items: rpl_items,
          region_ids: region_ids
        }).then(res => {
          console.log(res);
          if (res.code == 1) {
            this.newsetmeals = false;
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
          } else if (res.code == 2) {
            this.deletealtative = true;
          } else if (res.code == 3) {
            this.Seterrortxsf = true;
            this.Seterrorthree = {
              data: res.data,
              msg: res.msg
            };
          } else {
            this.$message.warning(res.msg);
          }
        });
      // }
    },

    // 删除绑定存货中的子选项
    subInventoryHandle(itemInfo) {
      const inventory = [...this.newmerchandise.inventory];
      const index = inventory.findIndex(item => item.id == itemInfo.id);
      if (index > -1) inventory.splice(index, 1);
      this.newmerchandise.inventory = [...inventory];
    },

    dainj() {
      console.log(1234);
    },
    // 滚动最大高度
    RollMaxHeight(i) {
      var s = i - 48 - 60 - 34 - 10;
      this.MaxHeight = s;
    },

    changeCheckedCitispesAll(e) {
      this.checkedCitispes = e ? this.ImportDatas.map(item => item.id) : [];
    },
    
     // 上传的商品图片
    prdImgLoadHandle(){
      const img = this.$refs.prdImgLoad || {}
      const imgPrev = document.querySelectorAll('.prdImgLoadImg')
      if (img.width > img.height) {
        img.style.width = 90 + 'px'
        img.style.height = 'auto'
      } else {
        img.style.height = 90 + 'px'
        img.style.width = 'auto'
      }
      if(imgPrev.length > 0) {
        imgPrev.forEach(el => {
          if (el.width > el.height) {
            el.style.width = 100 + 'px'
            el.style.height = 'auto'
          } else {
            el.style.width = 'auto'
            el.style.height = 100 + 'px'
          }
        })
      }
    },

    showOrHideDetailDialog(){
      this.dialogDelVisible = !this.dialogDelVisible
    },

    async deleteSureHandle(){

      const params = {ids: this.checkedCities}
      try {
        const res = await this.$api.BMS.Prd.requestprddel(params)
        if (res.code == 1) {
          this.$message.success('操作成功')
          this.showOrHideDetailDialog()
          this.QuantityProduction = false
          this.newsetmeals = false
          this.nr = ''
          eventVue.$emit('reloadTableData')
        } else if (res.code == 2) {
          this.dialogFible = true;
          this.srnr = "批量删除";
          res.data.ns = res.data.ns || []
          res.data.cs = (res.data.cs || []).map(item => item.r)
          this.cwsm.ns = res.data.ns || []
          this.cwsm.ns = [...res.data.ns, ...res.data.cs]
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('删除员工失败', error)
      }
    },
  },
  computed: {
    setmea() {
      return JSON.parse(JSON.stringify(this.setmeals));
    },
    newmerchand() {
      return JSON.parse(JSON.stringify(this.newmerchandise));
    },
    substute() {
      return JSON.parse(JSON.stringify(this.substitute));
    },
    checkedCitisp() {
      return JSON.parse(JSON.stringify(this.checkedCitispes));
    }
  },
  watch: {
    windowHeigh(val) {
      let that = this;
      this.RollMaxHeight(val);
      //   console.log("实时屏幕高度：",val, that.windowHeigh );
    },
    windowWidt(val) {
      let that = this;
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    },
    // 模糊查询
    nr: {
      deep: true,
      handler: function(after, before) {
        // console.log(after);
        if (this.timer) {
          clearTimeout(this.timer);
        }
        this.timer = setTimeout(() => {
          if (after == "") {
            this.sfshow = true;
          } else {
            this.searchesult = {
              yij: [],
              erj: [],
              wl: [],
              sl: ""
            };
            this.sfshow = false;
            this.$api.BMS.Prd.requestprdcatesearch({ name: after }).then(
              res => {
                if (res.code == 1) {
                  for (const key in res.data) {
                    if (res.data[key].t == 1) {
                      this.searchesult.yij.push(res.data[key]);
                    } else if (res.data[key].t == 2) {
                      this.searchesult.erj.push(res.data[key]);
                    } else if (res.data[key].t == 3 || res.data[key].t == 4) {
                      this.searchesult.wl.push(res.data[key]);
                    }
                  }
                  this.tjflyj();
                  // console.log(res.data);
                  var s = res.data || [];
                  this.searchesult.sl = s.length;
                } else {
                  this.$message.warning(res.msg);
                }
              }
            );
          }
        }, 500);
      }
    },
    //
    stairNames: {
      deep: true,
      handler: function(after, before) {
        console.log(after);
        this.gaibland = "全部";
        // if(after != ''){
        //     this.gaibland = after
        // }else{
        //     this.gaibland = '全部'
        // }
      }
    },
    secondNames: {
      deep: true,
      handler: function(after, before) {
        // console.log(after);
        if (after != "") {
          this.gaibland = after;
        } else {
          this.gaibland = this.$route.params.id;
        }
      }
    },
    materialNames: {
      deep: true,
      handler: function(after, before) {
        console.log(after);
        if (after != "") {
          this.gaibland = after;
        } else {
          this.gaibland = this.$route.params.id;
        }
      }
    },

    // 编辑 根据商品名称改变拼音 限制价格
    compileMate: {
      deep: true,
      handler: function(after, before) {
        // 根据商品名称改变拼音
        if (after.name != before.name) {
          this.$api.UtilAuth.util
            .requestutilpy({ str: after.name })
            .then(res => {
              this.compileMaterial.phoneticize = res.data || "";
            });
        }
        console.log(after.customprop);
      }
    },
    // 编辑 根据所选单位添加比例
    compileMatMatere: {
      deep: true,
      handler: function(after, before) {
        // console.log(after);

        var reg = /^[0-9]+(\.[0-9]{0,2})?$/;
        for (const key in this.compileMaterial.ListUnits) {
          for (const ke in after) {
            if (after[ke].id == this.compileMaterial.ListUnits[key].id) {
              this.compileMaterial.Materialunit[
                ke
              ].ratio = this.compileMaterial.ListUnits[key].us;
              // console.log(this.compileMaterial.ListUnits[key].ut);
              // console.log(this.compileMaterial.Materialunit[ke]);
              this.compileMaterial.Materialunit[
                ke
              ].ut = this.compileMaterial.ListUnits[key].ut;
            }
            if (after[ke].bp || "" == (before[ke] || {}).bp || "") {
              if (!reg.test(after[ke].bp)) {
                this.compileMaterial.Materialunit[ke].bp =
                  (before[ke] || {}).bp || "";
              }
            }
            if (after[ke].sp || "" == (before[ke] || {}).sp || "") {
              if (!reg.test(after[ke].sp)) {
                this.compileMaterial.Materialunit[ke].sp =
                  (before[ke] || {}).sp || "";
              }
            }
          }
        }
        // console.log(after[0]);
        // console.log(before[0]);
      }
    },
    // 编辑 根据所选单位添加比例 价格只允许输入数字
    addbjpupss: {
      deep: true,
      handler: function(after, before) {
        for (const key in this.compileMaterial.ListUnits) {
          if (after.unitid == this.compileMaterial.ListUnits[key].id) {
            this.addbjpopup.proportion = this.compileMaterial.ListUnits[key].us;
            this.addbjpopup.ut = this.compileMaterial.ListUnits[key].ut;
          }
        }
        // 只让输入数字  限制小数点后有两位就不能输入了
        if (after.purchase) {
          var reg = /^[0-9]+(\.[0-9]{0,2})?$/;
          if (!reg.test(after.purchase)) {
            this.addbjpopup.purchase = before.purchase;
          }
        }
        if (after.market) {
          var reg = /^[0-9]+(\.[0-9]{0,2})?$/;
          if (!reg.test(after.market)) {
            this.addbjpopup.market = before.market;
          }
        }
      }
    },
    dept_code: {
      deep: true,
      handler: function(after, before) {
        console.log(after[after.length - 1]);
        this.erp_prds.erp_cate_code = after[after.length - 1];

        // this.prderp_prds()
        this.checkedCitispes = [];
        if (this.$refs.cascaderRef) {
          this.$refs.cascaderRef.dropDownVisible = false;
        }
      }
    },
    commoditycode: {
      deep: true,
      handler: function(after, before) {
        // this.erp_prds.erp_cate_code = after[after.length-1]
        console.log(after);
        this.setmeals.one_cate_id = after[0] || 0;
        this.setmeals.two_cate_id = after[1] || 0;
        this.gett_wwite();
        // this.checkedCitispes = []
        if (this.$refs.cascaderRef) {
          this.$refs.cascaderRef.dropDownVisible = false;
        }
      }
    },
    // 根据商品名称改变拼音 限制价格
    newmerchand: {
      deep: true,
      handler: function(after, before) {
        // console.log(/^[a-zA-z]$/.test(after.English));
        // 根据商品名称改变拼音
        if (after.name != before.name) {
          this.$api.UtilAuth.util
            .requestutilpy({ str: after.name })
            .then(res => {
              this.newmerchandise.phoneticize = res.data || "";
            });
        }
        if (after.SKUtype == 4 || after.SKUtype == 5 || after.SKUtype == 6) {
          this.newmerchandise.Inventorygoods = false;
        } else {
          this.newmerchandise.Inventorygoods = true;
        }
        if (
          after.SKUtype == 3 ||
          after.SKUtype == 4 ||
          after.SKUtype == 5 ||
          after.SKUtype == 6 ||
          after.SKUtype == 13 ||
          after.SKUtype == 14
        ) {
          this.newmerchandise.businesstype = [3, 8, 4, 13, 14].includes(
            after.SKUtype * 1
          )
            ? "2"
            : "2";
          this.newmerchandise.forbidden = true;
        }
        if (before.SKUtype != after.SKUtype) {
          if (after.SKUtype == 1 || after.SKUtype == 6 || after.SKUtype == 13 || after.SKUtype == 14) {
            if (after.price == before.price) {
              this.newmerchandise.price = "";
              this.newmerchandise.marketprices = false;
            }
          }
        }
        if (after.SKUtype == 3 || after.SKUtype == 4 || after.SKUtype == 5) {
          this.newmerchandise.price = "时价";
          this.newmerchandise.marketprices = true;
        }
        if (after.SKUtype == 1) {
          this.newmerchandise.forbidden = false;
        }
      }
    },
    // 根据商品名称改变拼音 限制价格
    setmea: {
      deep: true,
      handler: function(after, before) {
        // console.log(/^[a-zA-z]$/.test(after.English));
        // 根据商品名称改变拼音
        if (after.name != before.name) {
          this.$api.UtilAuth.util
            .requestutilpy({ str: after.name })
            .then(res => {
              this.setmeals.phoneticize = res.data || "";
            });
        }
      }
    },
    // 判断替换组可选数量  进行限制
    substute: {
      deep: true,
      handler: function(after, before) {
        var i = "";
        if (after.length == before.length) {
          for (const key in after) {
            if (after[key].sel_cnt != before[key].sel_cnt) {
              var reg = /^[0-9]*$/;
              if (!reg.test(after[key].sel_cnt)) {
                this.substitute[key].sel_cnt = before[key].sel_cnt;
                this.$message.warning("请输入数字");
              } else if (after[key].sel_cnt.length > 4) {
                this.substitute[key].sel_cnt = before[key].sel_cnt;
                this.$message.warning("最大支持四位数字");
              } else if (parseInt(after[key].sel_cnt) === 0) {
                this.substitute[key].sel_cnt = "";
                this.$message.warning("输入必须大于零");
              }
            }
            if (after[key].deletejudge != before[key].deletejudge) {
              if (after[key].deletejudge == true) {
                i = Number(key);
              }
            }
          }
          if (typeof i == "number") {
            for (const key in after) {
              if (i == key) {
                this.substitute[key].deletejudge = true;
              } else {
                this.substitute[key].deletejudge = false;
              }
            }
          }
        }
      }
    },
    checkedCitisp: {
      deep: true,
      handler: function(after, before) {
        if (after.length > 1) {
          // this.checkedCitispes = after.slice(-1);
          // console.log(this.checkedCitispes);
        }
      }
    },

    checkedCitispes(newVal) {
      this.isIndeterminateAll =
        newVal.length != this.ImportDatas.length && newVal.length > 0;
      this.checkedCitispesAll = newVal.length == this.ImportDatas.length;
    }
  }
};
</script>
<style>
.Singless {
  /* width: calc(100% - 40px);
        height: calc(100% - 80px);
        padding:40px 20px; */
  height: calc(100% - 40px);
  display: flex;
}

.searchselect {
  padding-top: 40px;
  width: 200px;
  height: 100%;
  overflow-y: auto;
  border-right: 1px solid #eee;
}

.searchselect .classifysearch {
  width: 180px;
  margin-left: 10px;
}

.searchselect .el-input {
  font-size: 12px;
}

.searchselect .routerlinkyus {
  color: #08080a;
  position: relative;
}

.searchselect .routerlinkyus:after {
  content: " ";
  width: 40px;
  height: 40px;
  position: absolute;
  left: -40px;
  top: 0;
}

/* 折叠面板 */
.searchselect .collapse {
  padding: 0 10px;
  max-height: 700px;
  overflow-x: scroll;
  overflow: overlay;
}

.searchselect .collapse .el-collapse {
  border-top: 0px !important;
}

/* slot放到左边 */
.searchselect .collapse .collapse-title {
  display: flex;
  align-items: center;
  flex: 1 0 90%;
  order: 1;
  line-height: 40px;
}

.searchselect .collapse .el-collapse-item__header {
  flex: 1 0 auto;
  order: -1;
  font-size: 14px !important;
  background-color: #f9f9f9 !important;
  border-bottom: 0px !important;
  color: #8c8c8c;
  height: 40px;
  /* padding-left: 18px; */
  font-size: 18px;
  /* margin: 4px 6px 4px 6px; */

  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

/* 图标大小 */
.searchselect .collapse .icons {
  width: 14px;
  height: 14px;
  margin-right: 4px;
}

.searchselect .collapse .el-collapse-item__arrow {
  margin: 0 4px 0 auto;
}

.searchselect .collapse .el-collapse-item__wrap {
  background-color: #f9f9f9 !important;
  border-bottom: 0px;
}

.searchselect .collapse .el-collapse-item__content {
  padding-bottom: 0px;
}

/* 一级列表 */
.searchselect .collapse .stair {
}

.searchselect .collapse .stair .el-collapse-item__header {
  padding-left: 18px;
}

/* 二级列表 */
.searchselect .collapse .second {
  display: flex;
  align-items: center;
  height: 40px;
  line-height: 40px;
  padding-left: 54px;
  text-align: left;
  color: #8c8c8c;
  font-size: 14px;
  /* 鼠标小手 */
  cursor: pointer;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  border-radius: 6px;
}
</style>
<style>
.Singless .eresult {
  /* padding-right: 6px; */
  max-height: 700px;
  overflow-x: scroll;
  overflow: overlay;
}

.Singless .eresult .lbao {
  margin-top: 20px;
}

.Singless .eresult .lbao .liebia {
  height: 40px;
  line-height: 40px;
  font-size: 12px;
  color: #8c8c8c;
  padding-left: 10px;
}

.Singless .eresult .lbao .yansnafe {
  margin: 0 10px;
  border-radius: 6px;
}

.Singless .eresult .lbao .lbnrs {
  height: 40px;
  width: 100%;
  display: flex;
  align-items: center;
}

.Singless .eresult .lbao .lbnrs:hover {
  background-color: #d7e9ff;
  border-radius: 6px;
}

.Singless .eresult .lbao .lbnrs img {
  margin-left: 14px;
  width: 14px;
  height: 14px;
}

.Singless .eresult .lbao .lbnrs div {
  margin-left: 4px;
  color: #40404e;
  font-size: 14px;
}

.Singless .searchselect .eresult .meiy {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 128px;
}

.Singless .searchselect .eresult .meiy img {
  width: 60px;
  height: 60px;
}

.Singless .searchselect .eresult .meiy div {
  margin-top: 20px;
  font-size: 14px;
  color: #40404e;
}
</style>
<style>
/* 表格无数据时展示 */
.Prds .drag-list .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.Prds .drag-list .nodata img {
  width: 60px;
  height: 60px;
}

.Prds .drag-list .nodata .hint {
  font-size: 13px !important;
}

/* 下拉框 */
.el-select-dropdown__wrap {
  background-color: #f5f5f5;
}

.el-select-dropdown__empty {
  background-color: #f5f5f5;
  color: #40404e;
}

.el-select-dropdown__item.selected {
  background-color: #e5e5e5;
}

.el-select__popper.el-popper[role="tooltip"] {
  border: 1px solid #f5f5f5;
}

.el-select__popper.el-popper[role="tooltip"][data-popper-placement^="bottom"]
  .el-popper__arrow::before {
  border: 1px solid #f5f5f5;
  background-color: #f5f5f5;
}

.el-select-dropdown__item.hover,
.el-select-dropdown__item:hover {
  background-color: #e5e5e5;
}

.el-select-dropdown__item.selected {
  color: #40404e;
}

.el-select-dropdown__item {
  color: #40404e;
}

.el-select-dropdown {
  border: 1px solid #f5f5f5;
}

/* 靠右 */
.Prds .el-dialog {
  margin: 0px 0px 0px auto !important;
  height: 100%;
  position: relative;
}

.Prds .el-dialog__body {
  padding: 0px 0px 30px 20px;
  overflow-y: scroll !important;
  width: 100%;
  width: calc(100% - 40px);
  height: calc(100% - 160px);
  max-height: calc(100% - 160px);
  margin: 0;
}

.Prds .el-dialog {
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.Prds .el-dialog__footer {
  position: absolute;
  width: 100%;
  bottom: 0;
  right: 0;
  display: flex;
  justify-content: center;
}

/* 必填 */
.Prds .mandatory {
  color: #40404e;
  width: 140px;
  text-align: right;
  /* padding-top: 10px; */
  line-height: 41px;
}

.Prds .controlling {
  color: #40404e;
  width: 230px !important;
  line-height: 40px;
}

.Prds .reqfieldsd {
  font-size: 16px;
  padding-right: 4px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Prds .dialogPrinter .el-form {
  padding-top: 10px !important;
}

.Prds .el-dialog .el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
}

.Prds .el-dialog {
  background-color: #f9f9f9;
}

.Prds .el-input__inner {
  background-color: transparent;
  color: #40404e;
}

.Prds .el-dialog__title,
.Prds .el-dialog__headerbtn .el-dialog__close,
.Prds .el-form-item__label {
  color: #1a1a21;
  display: flex;
  align-items: center;
}

.Prds table {
  border-collapse: collapse;
  /* border: solid 1px #f5f5f5; */
  color: #40404e;
}

/* 新建商品 */
.Prds .dialogPrinter .el-dialog {
  /* width: 50vw !important;
        min-width: 620px !important;
        max-width:620px !important; */
  width: 1280px;
}

.Prds .dialogPrinter .el-dialog__body {
  padding: 10px;
}

.Prds .dialogPrinter .Materialunit {
  width: 1060px;
  border: 1px solid #40404e;
  padding: 10px;
}

.Prds .dialogPrinter .biaot {
  font-size: 24px;
  color: #40404e;
  text-align: center;
  margin-bottom: 10px;
}

.Prds .dialogPrinter .compa-tib {
  color: #40404e;
}

.Prds .dialogPrinter .rial-unit {
  display: flex;
}

.Prds .dialogPrinter .rial-unit .miaos {
  line-height: 34px;
  width: 630px;
  margin-left: 20px;
  color: #40404e;
}

.Prds .dialogPrinter .el-button--mini,
.el-button--small {
  font-size: 14px !important;
}

.Prds .compatibil {
  margin-bottom: 10px;
}

.Prds .compatibility {
  display: flex;
  /* align-items: center; */
  margin-bottom: 5px;
}

/* 单位 */
.Prds .dialogPrinter .Mater-unit .drag-list .nodata {
  height: 180px !important;
}

.Prds .dialogPrinter .Mater-unit .drag-list td {
  line-height: 39px !important;
  display: flex;
  align-items: center;
}

.Prds .dialogPrinter .Mater-unit .lans {
  color: #409eff;
}

.Prds .dialogPrinter .Mater-unit .lans:hover {
  color: #66b1ff;
}

.Prds .dialogPrinter .Mater-unit .drag-list td:nth-of-type(1),
.Prds .dialogPrinter .Mater-unit .mmodity th:nth-of-type(1) {
  width: 70px;
}

.Prds .dialogPrinter .Mater-unit .drag-list td:nth-of-type(2),
.Prds .dialogPrinter .Mater-unit .mmodity th:nth-of-type(2) {
  width: 200px;
}

.Prds .dialogPrinter .Mater-unit .drag-list td:nth-of-type(3),
.Prds .dialogPrinter .Mater-unit .mmodity th:nth-of-type(3) {
  width: 100px;
}

.Prds .dialogPrinter .Mater-unit .drag-list td:nth-of-type(4),
.Prds .dialogPrinter .Mater-unit .mmodity th:nth-of-type(4) {
  width: 150px;
}

.Prds .dialogPrinter .Mater-unit .drag-list td:nth-of-type(5),
.Prds .dialogPrinter .Mater-unit .mmodity th:nth-of-type(5) {
  width: 150px;
}

/* Mater-unit */
/* 扩展属性 */
.Prds .dialogPrinter .annkz {
  display: flex;
  justify-content: center;
}

/* 自定义属性 */
.Prds .user-defined .el-dialog {
  width: 720px !important;
}

.Prds .user-defined .explain {
  /* color: #40404e; */
  /* margin-bottom:10px ; */
  margin-top: 20px;
  color: #ce4153;
  font-size: 12px;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Prds .user-defined .el-form {
  padding-top: 20px !important;
}

.Prds .user-defined .attribute {
  /* width: 90%; */
  width: 350px;
  display: flex;
  flex-direction: column;
}

.Prds .user-defined .attribute > div {
  display: flex;
}

.Prds .user-defined .el-input {
  width: 230px;
  /*margin-bottom: 10px;*/
}

.Prds .user-defined .el-form-item__content {
  /* width: 100%; */
  display: flex;
  margin-bottom: 10px;
}

.Prds .user-defined .compatibil .compatibility {
  align-items: flex-start;
}

.Prds .user-defined .compatibil .compatibility .el-button {
  width: 40px;
  height: 40px;
  margin-left: 10px;
}

/* 编辑商品 */
.Prds .dialogPrinter .needattention {
  /* margin-bottom: 10px; */
  font-size: 12px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Prds .dialogPrinter .fenge {
  box-sizing: border-box;
  width: 100%;
  border: 1px solid rgb(61, 61, 61);
  padding: 10px 0;
  margin-bottom: 10px;
}

.Prds .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(1),
.Prds .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(1) {
  width: 70px;
}

.Prds .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(2),
.Prds .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(2) {
  width: 170px;
}

.Prds .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(3),
.Prds .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(3) {
  width: 70px;
}

.Prds .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(4),
.Prds .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(4) {
  width: 140px;
}

.Prds .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(5),
.Prds .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(5) {
  width: 140px;
}

.Prds .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(6),
.Prds .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(6) {
  width: 70px;
}

.Prds .dialogPrinter .fenge .Mater-unit .el-button + .el-button {
  margin-left: 0;
}

/* 编辑 添加商品单位 */
.Prds .editaddunit .el-dialog {
  width: 720px !important;
}

.Prds .editaddunit .requimeiytgy {
  color: #40404e;
  font-size: 20px;
}

/* 新建商品 */
.Prds .dialogPrinter .el-dialog {
  width: 790px;
  /*margin-top: 50px !important;*/
}

.Prds .dialogPrinter .el-dialog__body {
  padding: 10px;
}

.Prds .dialogPrinter .Materialunit {
  border: 1px solid #40404e;
  padding: 10px;
}

.Prds .dialogPrinter .biaot {
  font-size: 24px;
  color: #40404e;
  text-align: center;
  margin-bottom: 10px;
}

.Prds .dialogPrinter .compa-tib {
  color: #40404e;
}

.Prds .dialogPrinter .rial-unit {
  display: flex;
}

.Prds .dialogPrinter .rial-unit div {
  width: 530px;
  margin-left: 20px;
  color: #40404e;
}

.Prds .dialogPrinter .el-button--mini,
.el-button--small {
  font-size: 14px !important;
}

.Prds .compatibil {
  margin-bottom: 10px;
}

.Prds .compatibility {
  display: flex;
  margin-bottom: 5px;
}

.Prds .dialogPrinter .Mater-unit {
  margin-top: 10px;
  font-size: 14px;
  overflow: hidden;
  display: inline-block;
  border-left: 1px solid #f5f5f5;
}

.Prds .dialogPrinter .limiting {
  width: 100%;
  overflow: auto !important;
  max-height: 210px !important;
  border-bottom: solid 1px #f5f5f5;
  display: block;
}

/* 单品商品区域 */
.Prds .dialogPrinter .annkz {
  display: flex;
  justify-content: center;
}

.Prds .dialogPrinter .extend-unit {
  margin-left: 70px;
  font-size: 14px;
  overflow: inherit;
  display: inline-block;
  border-left: 1px solid #f5f5f5;
}

.Prds .dialogPrinter .extend-unit .drag-list td:nth-of-type(1),
.Prds .dialogPrinter .extend-unit .mmodity th:nth-of-type(1) {
  width: 70px;
}

.Prds .dialogPrinter .extend-unit .drag-list td:nth-of-type(2),
.Prds .dialogPrinter .extend-unit .mmodity th:nth-of-type(2) {
  width: 230px;
}

.Prds .dialogPrinter .extend-unit .drag-list td:nth-of-type(3),
.Prds .dialogPrinter .extend-unit .mmodity th:nth-of-type(3) {
  width: 200px;
}

.Prds .dialogPrinter .extend-unit .drag-list td:nth-of-type(4),
.Prds .dialogPrinter .extend-unit .mmodity th:nth-of-type(4) {
  width: 100px;
}

/* 绑定epr商品 */
.Prds .user-defined .el-dialog {
  width: 650px !important;
}

.Prds .user-defined .explain {
  margin-top: 20px;
  color: #ce4153;
  font-size: 12px;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Prds .user-defined .el-form {
  padding-top: 20px !important;
}

.Prds .user-defined .attribute {
  width: 350px;
  display: flex;
  flex-direction: column;
}

.Prds .user-defined .el-input {
  width: 230px;
}

.Prds .user-defined .el-form-item__content {
  display: flex;
  margin-bottom: 10px;
}

.Prds .user-defined .compatibil .compatibility {
  align-items: flex-start;
}

.Prds .user-defined .compatibil .compatibility .el-button {
  width: 40px;
  height: 40px;
  margin-left: 10px;
}

.Prds .user-defined .zhuixiaoi {
  min-width: 602px !important;
  width: 602px;
  overflow: hidden;
  display: inline-block;
}

.Prds .user-defined .drag-list td:nth-of-type(1),
.Prds .user-defined .mmodity th:nth-of-type(1) {
  width: 70px;
}

.Prds .user-defined .drag-list td:nth-of-type(2),
.Prds .user-defined .mmodity th:nth-of-type(2) {
  width: 240px;
}

.Prds .user-defined .drag-list td:nth-of-type(3),
.Prds .user-defined .mmodity th:nth-of-type(3) {
  width: 210px;
}

.Prds .user-defined .drag-list td:nth-of-type(4),
.Prds .user-defined .mmodity th:nth-of-type(4) {
  width: 70px;
}

/* 新建套餐 */
.Prds .dialogsetmeal .el-dialog {
  width: 1280px;
  /*margin-top: 50px !important;*/
  /*margin-bottom: 50px !important;*/
}

.Prds .dialogsetmeal .el-form {
  padding-top: 5px;
}

.Prds .dialogsetmeal .tbdgf img {
  width: 15px;
  height: 15px;
}

.Prds .dialogsetmeal .item {
  margin: 4px 4px 4px -5px;
}

.Prds .dialogsetmeal .el-dialog__body {
  padding: 10px;
}

.Prds .dialogsetmeal .Materialunit {
  border: 1px solid #40404e;
  padding: 10px;
}

.Prds .dialogsetmeal .biaot {
  font-size: 24px;
  color: #40404e;
  text-align: center;
  margin-bottom: 10px;
}

.Prds .dialogsetmeal .compa-tib {
  color: #40404e;
}

.Prds .dialogsetmeal .rial-unit {
  display: flex;
}

.Prds .dialogsetmeal .rial-unit div {
  width: 530px;
  margin-left: 20px;
  color: #40404e;
}

.Prds .dialogsetmeal .el-button--mini,
.el-button--small {
  font-size: 14px !important;
}

.Prds .compatibil {
  margin-bottom: 10px;
}

.Prds .compatibility {
  display: flex;
  margin-bottom: 5px;
}

.Prds .dialogsetmeal .Mater-unit {
  margin-top: 10px;
  font-size: 14px;
  overflow: hidden;
  display: inline-block;
  border-left: 1px solid #f5f5f5;
}

.Prds .dialogsetmeal .limiting {
  width: 100%;
  display: block;
}

/* ERP商品 */
.Prds .in_sum-rkrq {
  color: #40404e;
  padding: 20px 0;
  display: flex;
}

.Prds .in_sum-rkrq .rkrq {
  margin-right: 15px;
  /* width: 280px; */
  display: flex;
  align-items: center;
}

.Prds .in_sum-rkrq .el-cascader__dropdown {
  background-color: #f5f5f5;
}

.Prds .in_sum-rkrq .rkrq > span {
  width: 50px;
  display: inline-block;
}

.Prds .in_sum-rkrq .rkrq .el-select {
  width: 230px;
}

.Prds .in_sum-rkrq .rkrq .el-input {
  width: 220px;
}

.Prds .in_sum-rkrq .rkrq:nth-of-type(3) {
  width: 240px;
}

/* 级联选择器 */
.liebdwd .el-radio__inner {
  top: -18px;
  left: -19px;
  border-radius: 0;
  border: 0;
  width: 170px;
  height: 34px;
  background-color: transparent;
  cursor: pointer;
  box-sizing: border-box;
  position: absolute;
}

.liebdwd .el-radio__input.is-checked .el-radio__inner {
  background: transparent;
}

/* 禁用状态颜色 */
.Prds .dialogPrinter .el-input.is-disabled .el-input__inner {
  background-color: rgba(255, 255, 255, 0.075) !important;
  color: #b2b7c0;
}

.Prds .dialogPrinter .el-form {
  padding-top: 0px !important;
}

.Prds .controlling {
  width: 230px !important;
  color: #40404e;
  line-height: 40px;
  height: 40px;
}

.Prds .reqfieldsd {
  font-size: 16px;
  padding-right: 4px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

/* 表格全选字体颜色 */
.Prds .between .zhuixiaoi .el-checkbox__label {
  color: #40404e;
}

.Prds .between .zhuixiaoi .mmodity .el-checkbox__label {
  font-size: 12px;
}

/* 一级分类下没二级分类的时候 */
.Prds .between {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-top: 170px;
  padding-right: 400px;
}

.Prds .between img {
  width: 100px;
  height: 100px;
}

.Prds .between .period {
  margin-top: 30px;
  color: #a3a3a3;
  font-size: 18px;
}

/* 分页 */
.Prds .Pagination {
  /* width: 1093px; */
  text-align: right;
  margin-top: 20px;
}

.Prds .Pagination .el-pagination.is-background .btn-next,
.Prds .Pagination .el-pagination.is-background .btn-prev,
.Prd .Pagination .el-pagination.is-background .el-pager li {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #606266;
  color: #40404e;
}

.Prds .Pagination .btn-prev {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #606266;
}

.Prds .Pagination .el-pagination {
  padding: 0;
}

.Prds .Pagination .el-pagination .btn-next .el-icon,
.Singless .Pagination .el-pagination .btn-prev .el-icon {
  color: #40404e;
}

.Prds
  .Pagination
  .el-pagination.is-background
  .el-pager
  li:not(.disabled).active {
  color: #409eff;
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #409eff;
}

/* 表格无数据时展示 */
.Prds .dialogsetmeal .extend-unit .drag-list .nodata {
  height: 100px !important;
  border-left: none;
  padding: 0;
  width: 1108px !important;
}

.Prds .dialogsetmeal .extend-unit .drag-list {
  width: 100%;
  display: inline-block;
}

.Prds .dialogsetmeal .extend-unit .drag-list .Theewitem {
  cursor: pointer;
  display: inline-block;
  height: 50px;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 0;
  width: 1108px !important;
}

.Prds .dialogsetmeal .extend-unit .drag-list .Theewitem div:nth-of-type(1) {
  color: #438dfd;
  font-size: 15px;
  font-weight: bold;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Prds .dialogsetmeal .extend-unit .drag-list .Theewitem div:nth-of-type(2) {
  color: #438dfd;
  font-size: 15px;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Prds .dialogsetmeal .extend-unit .drag-list td:nth-of-type(1),
.Prds .dialogsetmeal .extend-unit .mmodity th:nth-of-type(1) {
  width: 49px;
}

.Prds .dialogsetmeal .extend-unit .drag-list td:nth-of-type(2),
.Prds .dialogsetmeal .extend-unit .mmodity th:nth-of-type(2) {
  width: 200px;
}

.Prds .dialogsetmeal .extend-unit .drag-list td:nth-of-type(3),
.Prds .dialogsetmeal .extend-unit .mmodity th:nth-of-type(3) {
  width: 210px;
}

.Prds .dialogsetmeal .extend-unit .drag-list td:nth-of-type(4),
.Prds .dialogsetmeal .extend-unit .mmodity th:nth-of-type(4) {
  width: 100px;
}

.Prds .dialogsetmeal .extend-unit .drag-list td:nth-of-type(5),
.Prds .dialogsetmeal .extend-unit .mmodity th:nth-of-type(5) {
  width: 120px;
}

.Prds .dialogsetmeal .extend-unit .drag-list td:nth-of-type(6),
.Prds .dialogsetmeal .extend-unit .mmodity th:nth-of-type(6) {
  width: 140px;
}

.Prds .dialogsetmeal .extend-unit .drag-list td:nth-of-type(7),
.Prds .dialogsetmeal .extend-unit .mmodity th:nth-of-type(7) {
  width: 90px;
}

.Prds .dialogsetmeal .extend-unit .drag-list td:nth-of-type(8),
.Prds .dialogsetmeal .extend-unit .mmodity th:nth-of-type(8) {
  width: 70px;
}

.Prds .dialogsetmeal .extend-unit .drag-list td:nth-of-type(9),
.Prds .dialogsetmeal .extend-unit .mmodity th:nth-of-type(9) {
  width: 70px;
}

.Prds .dialogsetmeal .extend-unit .drag-list td:nth-of-type(10),
.Prds .dialogsetmeal .extend-unit .mmodity th:nth-of-type(10) {
  width: 50px;
}

.Prds .zhuixiaoi .limiting .drag-list {
  display: block;
  display: flex;
}

.Prds .zhuixiaoi .drag-list:nth-of-type(even) {
  background-color: #f9f9f9;
  color: #40404e;
}

.Prds .zhuixiaoi .drag-list:nth-of-type(odd) {
  background-color: #f5f5f5;
  color: #40404e;
}

/* 列表 */
.zsykd {
  width: 100%;
  overflow-x: scroll !important;
}

.Prds .zhuixiaoi {
  /* width:1400px; */
  border-collapse: collapse;
  color: #40404e;
}

.Prds .zhuixiaoi .mmodity tr th {
  height: 36px;
  line-height: 36px;
  text-align: center;
  background-color: #f5f5f5;
  font-size: 14px;
  font-weight: 400;
}

.Prds .zhuixiaoi .mmodity tr th:nth-of-type(1) {
  border-left: solid 1px #f5f5f5;
}

.Prds .zhuixiaoi .limiting .drag-list td {
  height: 36px;
  line-height: 36px;
  text-align: center;
  /*border-right: solid 1px #f5f5f5;*/
  /* border-top: solid 1px #f5f5f5; */
  font-size: 14px;
  font-weight: 400;
}

.Prds .zhuixiaoi .limiting .drag-list td:nth-of-type(1) {
  border-left: solid 1px #f5f5f5;
}

.Prds .zhuixiaoi .limiting .drag-list {
  display: block;
  /* display: flex; */
}

.Prds .zhuixiaoi .mmodity {
  width: 100%;
  display: block;
}

.Prds .zhuixiaoi .mmodity tr {
  display: flex;
}

.Prds .zhuixiaoi .limiting {
  overflow-y: auto !important;
  max-height: 540px;
  /* border-bottom: solid 1px #f5f5f5; */
  display: block;
}

.Prds .drag-list td:nth-of-type(1),
.Prds .zhuixiaoi thead th:nth-of-type(1) {
  width: 80px;
}

.Prds .drag-list td:nth-of-type(2),
.Prds .zhuixiaoi thead th:nth-of-type(2) {
  width: 200px;
}

.Prds .drag-list td:nth-of-type(3),
.Prds .zhuixiaoi thead th:nth-of-type(3) {
  width: 140px;
}

.Prds .drag-list td:nth-of-type(4),
.Prds .zhuixiaoi thead th:nth-of-type(4) {
  width: 160px;
}

.Prds .drag-list td:nth-of-type(5),
.Prds .zhuixiaoi thead th:nth-of-type(5) {
  width: 100px;
}

.Prds .drag-list td:nth-of-type(6),
.Prds .zhuixiaoi thead th:nth-of-type(6) {
  width: 140px;
}

.Prds .drag-list td:nth-of-type(7),
.Prds .zhuixiaoi thead th:nth-of-type(7) {
  width: 105px;
}

.Prds .drag-list td:nth-of-type(8),
.Prds .zhuixiaoi thead th:nth-of-type(8) {
  width: 140px;
}

.Prds .drag-list td:nth-of-type(9),
.Prds .zhuixiaoi thead th:nth-of-type(9) {
  width: 140px;
}

.Prds .drag-list td:nth-of-type(10),
.Prds .zhuixiaoi thead th:nth-of-type(10) {
  width: 140px;
}

.Prds .drag-list td:nth-of-type(11),
.Prds .zhuixiaoi thead th:nth-of-type(11) {
  width: 70px;
}

/* 级联选择器 */
.el-cascader__dropdown {
  border: 1px solid #f5f5f5;
}

.el-cascader-menu__wrap {
  background-color: #f5f5f5;
}

.el-cascader-node:not(.is-disabled):hover {
  background-color: #e5e5e5;
  color: #40404e;
}

.el-cascader-node.in-active-path,
.el-cascader-node.is-active,
.el-cascader-node.is-selectable.in-checked-path {
  color: #409eff !important;
  background-color: #e5e5e5;
}

.el-radio__inner::after {
  background-color: #e5e5e5;
}

.el-cascader-node__label {
  color: #40404e;
}

.el-cascader-menu {
  border-right: solid 1px #4d4e5c;
}

/* 固定单品 */
.Prds .dialogsetmeal .annkz {
  display: flex;
  justify-content: center;
}

.Prds .dialogsetmeal .extend-unit {
  /* width: 1120px; */

  margin-left: 70px;
  font-size: 14px;
  overflow: inherit;
  display: inline-block;
}

/* 表格无数据时展示 */
.Prds .dialogsetmeal .extend-unit .drag-list .nodata {
  height: 100px !important;
  border-left: none;
  padding: 0;
  width: 1108px !important;
}

.Prds .dialogsetmeal .extend-unit .drag-list {
  width: 100%;
  display: inline-block;
}

/* 可替换 */
.Prds .dialogsetmeal .keorganize {
  display: flex;
  flex-direction: column;
  margin-bottom: 30px;
}

.Prds .dialogsetmeal .grouphandle {
  padding: 0 30px;
  height: 50px;
  display: flex;
  justify-content: space-between;
  margin-left: 70px;
  border: solid 1px #f5f5f5;
  border-bottom: 0px;
  align-items: center;
  width: 1048px;
}

.Prds .dialogsetmeal .choice {
  height: 60px;
  font-size: 20px;
  color: #40404e;
  display: flex;
  justify-content: flex-start;
  align-items: center;
}

.Prds .dialogsetmeal .deletereplace {
  font-size: 20px;
  color: #438dfd;
  cursor: pointer;
  margin-right: 20px;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Prds .dialogsetmeal .reddeletereplace {
  font-size: 20px;
  color: #fd4353;
  cursor: pointer;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

/* 可替换组高亮 类目更改 */
.Prds .highlight .grouphandle {
  border: solid 2px #ce4153;
  border-bottom: 0px;
}

.Prds .highlight .extend-unit .mmodity th:nth-of-type(1) {
  border-left: 2px solid #ce4153 !important;
}

.Prds .highlight .extend-unit .drag-list td:nth-of-type(1) {
  border-left: 2px solid #ce4153 !important;
}

.Prds .highlight .extend-unit .mmodity th:nth-of-type(10),
.Prds .highlight .extend-unit .drag-list td:nth-of-type(10) {
  border-right: 2px solid #ce4153 !important;
}

.Prds .highlight .extend-unit .drag-list .nodata {
  border-left: 2px solid #ce4153 !important;
  border-right: 2px solid #ce4153 !important;
}

.Prds .highlight .extend-unit .drag-list .Theewitem {
  border-left: 2px solid #ce4153 !important;
  border-bottom: 2px solid #ce4153 !important;
  border-right: 2px solid #ce4153 !important;
}

/* 提示 */
.hintimg {
  width: 15px;
  height: 15px;
  margin: 0px 0px 25px 5px;
}

.Prds .compatibility {
  display: flex;
  margin-bottom: 5px;
}

.Prds .dialogPrinter .Mater-unit {
  margin-top: 10px;
  font-size: 14px;
  overflow: hidden;
  display: inline-block;
  border-left: 1px solid #f5f5f5;
}

.Prds .dialogPrinter .limiting {
  width: 100%;
  overflow: auto !important;
  max-height: 210px !important;
  border-bottom: solid 1px #f5f5f5;
  display: block;
}

.Prds .el-radio-button__inner-div {
  padding: 0 20px;
}

/* 去除瑕疵 */
.Prds .el-radio-button__orig-radio:checked + .el-radio-button__inner + {
  box-shadow: none;
}

/*去除双击文字、input等，出现的蓝色底色*/
.container {
  -moz-user-select: none; /*火狐*/
  -webkit-user-select: none; /*webkit浏览器*/
  -ms-user-select: none; /*IE10*/
  /*-khtml-user-select:none;!*早期浏览器*!*/
  user-select: none;
  height: 30px;
}

.Prd-headline {
  font-size: 30px;
  font-weight: bold;
  color: #40404e;
}

.Prd-controller {
  /*margin-top: 30px;*/
  height: 54px;
  /*width: 1600px;*/
  background-color: #eee;
  display: flex;
  align-items: center;
}

.Prds table {
  border-collapse: collapse;
  /* border: solid 1px #f5f5f5; */
  color: #40404e;
}

.Prds table thead th {
  height: 40px;
  /* min-height: 40px; */
  line-height: 40px;
  text-align: center;
  font-weight: 400;
  font-size: 14px;
  background-color: #f5f5f5;
}

.Prds table tbody tr:nth-child(2n) {
  background-color: #f5f5f5;
}

.Prds table tbody td {
  height: 40px;
  min-height: 40px;
  line-height: 20px;

  text-align: center;
  white-space: normal;
  word-break: break-all;
  /* border: solid 1px #f5f5f5; */
  border-bottom: solid 1px #f5f5f5;
  border-right: solid 1px #f5f5f5;
  font-size: 14px;
  font-weight: 400;
}

.Prds .el-checkbox__label {
  color: #40404e;
}

.Prds .List-move {
  transition: transform 0.2s;
}

.Prds .zhuixiaoi {
  min-width: 867px;
  overflow: hidden;
  display: inline-block;
  /*margin-top: 6px;*/
}

.Prds .zhuixiaoi .limiting {
  width: 100%;
  overflow: auto !important;
  max-height: 540px;
  display: block;
}

.Prds .tolead .el-dialog {
  width: 30vw !important;
  min-width: 410px !important;
  max-width: 460px !important;
}

.Prds .feedback .el-dialog {
  width: 1300px !important;
}

.Prds .zhuixiaoi thead,
.Prd .zhuixiaoi thead tr,
.Prds .zhuixiaoi tbody tr {
  width: 100% !important;
}

.Prds .zhuixiaoi .drag-list {
  display: inline-block;
  width: 100% !important;
}

.Prds .check {
  color: #40404e;
}

.Prds .el-dialog .el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
}

.Prds .el-dialog {
  background-color: #f9f9f9;
}

.Prds .el-input__inner {
  background-color: transparent;
  color: #40404e;
}

.Prds .el-dialog__header,
.Prds .el-dialog__footer {
  background-color: #1a1a21;
}

.Prds .el-dialog__title,
.Prds .el-dialog__headerbtn .el-dialog__close,
.Prds .el-form-item__label {
  color: #1a1a21;
  display: flex;
  align-items: center;
}

.Prds .el-form-item {
  display: flex;
  margin: 0;
}

/* 金额 */
.money {
  /*text-align: right !important;*/
  /*width: 80%;*/
  /*padding: 0 10px;*/
}

.alignment .el-input__inner {
  text-align: right !important;
}

/* 新增替换组 */
.Prds .dialogsetmeal .setaddmeal {
  margin-left: 70px;
  border: dotted 3px #f5f5f5;
  width: 1108px !important;
  margin-bottom: 50px;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Prds .dialogsetmeal .setaddmeal .select {
  height: 60px;
  padding-left: 30px;
  font-size: 20px;
  color: #40404e;
  display: flex;
  justify-content: flex-start;
  align-items: center;
  opacity: 0.25;
}

.Prds .dialogsetmeal .setaddmeal .select div {
  height: 40px;
  border: solid 2px #f5f5f5;
  padding: 0px 20px;
  line-height: 40px;
}

.Prds .dialogsetmeal .setaddmeal .extend-unit {
  margin-left: 0px;
  opacity: 0.25;
}

.Prds .dialogsetmeal .setaddmeal .taddmeal {
  color: #438dfd;
  font-size: 24px;
  font-weight: 500;
  display: inline-block;
  height: 70px;
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
}

.Prds .dialogsetmeal .setaddmeal .taddmeal span {
  font-size: 20px;
  font-weight: bold;
}

.Prds .compatibility {
  display: flex;
  margin-bottom: 5px;
}

.Prds .dialogPrinter .Mater-unit {
  margin-top: 10px;
  font-size: 14px;
  overflow: hidden;
  display: inline-block;
  border-left: 1px solid #f5f5f5;
}

.Prds .dialogPrinter .limiting {
  width: 100%;
  overflow: auto !important;
  max-height: 210px !important;
  border-bottom: solid 1px #f5f5f5;
  display: block;
}

/* 单品商品区域 */
.Prds .dialogPrinter .annkz {
  display: flex;
  justify-content: center;
}

.Prds .dialogPrinter .extend-unit {
  margin-left: 70px;
  font-size: 14px;
  overflow: inherit;
  display: inline-block;
  border-left: 1px solid #f5f5f5;
}

.Prds .dialogPrinter .extend-unit .drag-list td:nth-of-type(1),
.Prds .dialogPrinter .extend-unit .mmodity th:nth-of-type(1) {
  width: 70px;
}

.Prds .dialogPrinter .extend-unit .drag-list td:nth-of-type(2),
.Prds .dialogPrinter .extend-unit .mmodity th:nth-of-type(2) {
  width: 230px;
}

.Prds .dialogPrinter .extend-unit .drag-list td:nth-of-type(3),
.Prds .dialogPrinter .extend-unit .mmodity th:nth-of-type(3) {
  width: 200px;
}

.Prds .dialogPrinter .extend-unit .drag-list td:nth-of-type(4),
.Prds .dialogPrinter .extend-unit .mmodity th:nth-of-type(4) {
  width: 100px;
}

/* 套餐区域 */
.Prds .dialogsetmeal .extend-unis .limiting {
  width: 100%;
  overflow: auto !important;
  max-height: 210px !important;
  border-bottom: solid 1px #f5f5f5;
  display: block;
}

.Prds .dialogsetmeal .extend-unis {
  margin-left: 70px;
  font-size: 14px;
  overflow: inherit;
  display: inline-block;
  border-left: 1px solid #f5f5f5;
}

.Prds .dialogsetmeal .extend-unis .drag-list td:nth-of-type(1),
.Prds .dialogsetmeal .extend-unis .mmodity th:nth-of-type(1) {
  width: 80px;
}

.Prds .dialogsetmeal .extend-unis .drag-list td:nth-of-type(2),
.Prds .dialogsetmeal .extend-unis .mmodity th:nth-of-type(2) {
  width: 700px;
}

.Prds .dialogsetmeal .extend-unis .drag-list td:nth-of-type(3),
.Prds .dialogsetmeal .extend-unis .mmodity th:nth-of-type(3) {
  width: 340px;
}

/* 图片预览 */
.Prds .imgDetails .el-dialog {
  width: 600px;
  border-left: 1px solid #f9f9f9;
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

/* 套餐绑定单品 */
.Prds .newdefined .loadmore {
  height: 40px;
  line-height: 40px;
  border-left: solid 1px #f5f5f5;
  border-right: solid 1px #f5f5f5;
}

.Prds .newdefined .el-dialog {
  width: 1100px !important;
}

.Prds .newdefined .zhuixiaoi .limiting {
  overflow-y: auto !important;
  max-height: 340px !important;
  border-bottom: solid 1px #f5f5f5;
  display: block;
}

.Prds .newdefined .explain {
  margin-top: 20px;
  color: #ce4153;
  font-size: 12px;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Prds .newdefined .el-form {
  padding-top: 20px !important;
}

.Prds .newdefined .attribute {
  width: 350px;
  display: flex;
  flex-direction: column;
}

.Prds .newdefined .el-input {
  width: 230px;
}

.Prds .newdefined .el-form-item__content {
  display: flex;
  margin-bottom: 10px;
}

.Prds .newdefined .compatibil .compatibility {
  align-items: flex-start;
}

.Prds .newdefined .compatibil .compatibility .el-button {
  width: 40px;
  height: 40px;
  margin-left: 10px;
}

.Prds .newdefined .zhuixiaoi {
  min-width: 602px !important;
  overflow: hidden;
  display: inline-block;
}

.Prds .newdefined .drag-list td:nth-of-type(1),
.Prds .newdefined .mmodity th:nth-of-type(1) {
  width: 70px;
}

.Prds .newdefined .drag-list td:nth-of-type(2),
.Prds .newdefined .mmodity th:nth-of-type(2) {
  width: 240px;
}

.Prds .newdefined .drag-list td:nth-of-type(3),
.Prds .newdefined .mmodity th:nth-of-type(3) {
  width: 210px;
}

.Prds .newdefined .drag-list td:nth-of-type(4),
.Prds .newdefined .mmodity th:nth-of-type(4) {
  width: 100px;
}

.Prds .newdefined .drag-list td:nth-of-type(5),
.Prds .newdefined .mmodity th:nth-of-type(5) {
  width: 140px;
}

.Prds .newdefined .drag-list td:nth-of-type(6),
.Prds .newdefined .mmodity th:nth-of-type(6) {
  width: 70px;
}

.Prds .newdefined .drag-list td:nth-of-type(7),
.Prds .newdefined .mmodity th:nth-of-type(7) {
  width: 90px;
}

.Prds .newdefined .drag-list td:nth-of-type(8),
.Prds .newdefined .mmodity th:nth-of-type(8) {
  width: 70px;
}

.drag-list-check {
  /* background: rgba(39, 52, 82, 0.5) !important; */
}

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

.prd_img {
  width: 90px;
  height: 90px;
}

.prd_img_btn {
  margin-top: 5px;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
}

.prd_img_btn_l,
.prd_img_btn_r {
  font-size: 14px;
  color: rgb(114, 152, 255);
}
</style>
