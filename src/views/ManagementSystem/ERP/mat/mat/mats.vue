<template>
  <div class="Single">
    <div>
      <div class="Single-controller">
        <icon-button @click.native="VolumeProduction" text="新增" img="btn_add.png" colors="#f5f5f5"></icon-button>
        <icon-button @click.native="staircompile" text="编辑" img="btn_edit.png" colors="#f5f5f5"></icon-button>
        <icon-button @click.native="noneffective" text="置为无效" img="btn_in_vain.png" colors="#f5f5f5"></icon-button>
        <icon-button @click.native="effective" text="置为有效" img="btn_effective.png" colors="#f5f5f5"></icon-button>
        <icon-button @click.native="printerdel" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
        <icon-button @click.native="DownloadBatch" text="批量导入" img="btn_batch_import.png" colors="#f5f5f5"></icon-button>
        <characters-button @click.native="editTwoCategoryHandle" colors="#383943" wz='批量修改物料分类'></characters-button>
      </div>
      <div style="position: relative">
        <div style="display: inline-block;" class="meisfgr">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>
                  <el-checkbox
                    :indeterminate="isIndeterminate"
                    v-model="checkAll"
                    @change="handleCheckAllChange"
                  >行号</el-checkbox>
                </th>
                <th>物料名称</th>
                <th>拼音简写</th>
                <th>物料单位</th>
                <th>有无空瓶回收</th>
                <th>创建时间</th>
                <th>更新时间</th>
                <th>状态</th>
              </tr>
            </thead>
            <tbody
              class="limiting"
              ref="systemForm"
              @scroll="sysHandleScroll()"
              @mouseover="changeFlag(false)"
              :style="{
                'width':merchandise.length>12?'calc(100% + 6px)':'100%',
                'border-bottom':merchandise.length<1?'0px':'',
                    'max-height':`${MaxHeight}px`}"
            >
              <tr
                v-for="(item,i) in merchandise"
                :key="item.id"
                class="drag-list"
                :class="checkedCities.includes(item.id)? 'drag-list-check':''"
              >
                <td :style="{'color':item.s=='无效'?'#595959':''}">
                  <el-checkbox-group v-model="checkedCities" @change="handleCheckedCitiesChange">
                    <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                  </el-checkbox-group>
                </td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">
                  <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                </td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">
                  <ellipsis-tooltip :text="item.np || '-----'"></ellipsis-tooltip>
                </td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">
                  <ellipsis-tooltip :text="item.un || '-----'"></ellipsis-tooltip>
                </td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.r}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
              </tr>
            </tbody>
          </table>
          <div class="tiaodd" v-if="merchandise.length<1">
            <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
              <img src="../../../../../assets/img/wu.png" alt />
              <div class="hint">暂无数据</div>
            </td>
          </div>
        </div>
        <div
          style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;"
        >
          <table class="zhuixiaoi zhuixiaoi_l" style="width: auto;">
            <thead class="mmodity">
              <tr>
                <th>
                  <el-checkbox
                    :indeterminate="isIndeterminate"
                    v-model="checkAll"
                    @change="handleCheckAllChange"
                  >行号</el-checkbox>
                </th>
                <th>物料名称</th>
              </tr>
            </thead>
            <tbody
              class="limiting"
              ref="externalForm"
              @scroll="exterHandleScroll()"
              @mouseover="changeFlag(true)"
              :style="{
                'width':merchandise.length>12?'calc(100% + 6px)':'100%',
                'border-bottom':merchandise.length<1?'0px':'',
                    'max-height':`${MaxHeight}px`}"
            >
              <tr
                v-for="(item,i) in merchandise"
                :key="item.id"
                class="drag-list"
                :class="checkedCities.includes(item.id)? 'drag-list-check':''"
              >
                <td :style="{'color':item.s=='无效'?'#595959':''}">
                  <el-checkbox-group v-model="checkedCities" @change="handleCheckedCitiesChange">
                    <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                  </el-checkbox-group>
                </td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">
                  <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 新增物料 -->
    <div class="dialogPrinter" v-show="QuantityProduction">
      <el-dialog
        title="新增物料"
        :visible.sync="QuantityProduction"
        @close="QuantityProduction = false"
        :close-on-click-modal="false"
      >
        <!-- <div class="biaot">基本属性</div> -->
        <el-form label-position="left">
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>物料名称：
              </div>
              <el-input
                v-model="newmerchandise.name"
                placeholder="请输入物料名称"
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
                <span class="reqfieldsd"></span>物料空瓶回收：
              </div>
              <el-radio v-model="newmerchandise.rtn_bottle" label="1">有</el-radio>
              <el-radio v-model="newmerchandise.rtn_bottle" label="2">无</el-radio>
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>物料单位：
              </div>
              <el-select
                v-model="newmerchandise.specification"
                placeholder="请选择物料单位"
                class="controlling"
              >
                <el-option
                  v-for="each in newmerchandise.ficati"
                  :key="each.id"
                  :label="each.n"
                  :value="each.id"
                ></el-option>
              </el-select>
            </div>
          </div>
          <!-- <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd">*</span>物料单位：
                            </div>
                            <div class="Materialunit">
                                <div class="rial-unit">
                                    <icon-button @click.native="addMaterialunit" text="新增" img="btn_add.png"
                                                 colors="#f5f5f5"></icon-button>
                                    <icon-button @click.native="deleteMaterialunit" text="删除" img="btn_delete.png"
                                                 colors="#6B2830" bjcolors="#491E24"></icon-button>
                                    <div class="miaos">【如物料有多种单位；例如支、箱等，则需要将不同的单位都添加；】</div>
                                </div>
                                <table class="Mater-unit">
                                    <thead class="mmodity">
                                    <tr>
                                        <th>
                                            <el-checkbox :indeterminate="unit_isIndeterminate" v-model="unit_checkAll"
                                                         @change="unit_handleCheckAllChange">行号
                                            </el-checkbox>
                                        </th>
                                        <th>单位</th>
                                        <th>比例</th>
                                        <th>默认采购价</th>
                                        <th>默认销售价</th>
                                    </tr>
                                    </thead>
                                    <tbody class="limiting" :style="{
                                    'width':newmerchandise.Materialunit.length>4?'calc(100% + 6px)':'calc(100% + 6px)',
                                    'border-bottom':newmerchandise.Materialunit.length<1?'0px':''}">
                                    <tr v-for="(item,i) in this.newmerchandise.Materialunit" :key="i" class="drag-list"
                                        :class="unit_checkedCities.includes(item.i)? 'drag-list-check':''">
                                        <td>
                                            <el-checkbox-group v-model="unit_checkedCities"
                                                               @change="unit_handleCheckedCitiesChange">
                                                <el-checkbox :label="item.i">{{i+1}}</el-checkbox>
                                            </el-checkbox-group>
                                        </td>
                                        <td>
                                            <el-select v-model="newmerchandise.Materialunit[i].id"
                                                       placeholder="请选择物料单位">
                                                <el-option v-for="each in newmerchandise.ListUnits" :key="each.id"
                                                           :label="each.n" :value="each.id"></el-option>
                                            </el-select>
                                        </td>
                                        <td>{{item.ratio}}</td>
                                        <td>
                                            <el-input v-model="item.bp" placeholder="输入价格"/>
                                        </td>
                                        <td>
                                            <div v-show="item.ut == 2">—</div>
                                            <el-input v-show="item.ut == 1" v-model="item.sp" placeholder="输入价格"/>
                                        </td>
                                    </tr>
                                    <tr class="drag-list" v-if="newmerchandise.Materialunit.length<1">
                                        <td class="nodata">
                                            <img src="../../../../../assets/img/wu.png" alt="">
                                            <div class="hint">暂无数据</div>
                                        </td>
                                    </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
          </div>-->
        </el-form>
        <!-- <div class="biaot">扩展属性</div>
                <div class="annkz">
                    <icon-button @click.native="addproperty" style="margin: 0px 8px;" text="新增" img="btn_add.png"
                                 colors="#f5f5f5"></icon-button>
                    <icon-button @click.native="compilecustomproperty" style="margin: 0px 8px;" text="编辑" img="btn_edit.png"
                                 colors="#f5f5f5"></icon-button>
                    <icon-button @click.native="deleteproperty" style="margin: 0px 8px;" text="批量删除" img="btn_delete.png"
                                 colors="#6B2830" bjcolors="#491E24"></icon-button>
                </div>
                <el-form label-position="left">
                    <div class="compatibil">
                        <div class="compatibility">
                            <div class="mandatory">
                                <span class="reqfieldsd"></span>自定义属性：<br>（最多添加6个）
                            </div>
                            <table class="extend-unit" style="margin-left: 10px;">
                                <thead class="mmodity">
                                <tr>
                                    <th>
                                        <el-checkbox :indeterminate="nature_isIndeterminate" v-model="nature_checkAll"
                                                     @change="nature_handleCheckAllChange">行号
                                        </el-checkbox>
                                    </th>
                                    <th>属性名称</th>
                                    <th>属性值</th>
                                </tr>
                                </thead>
                                <tbody class="limiting" :style="{
                                'width':newmerchandise.customprop.length>4?'calc(100% + 6px)':'calc(100% + 6px)',
                                'border-bottom':newmerchandise.customprop.length<1?'0px':''}">
                                <tr v-for="(item,i) in newmerchandise.customprop" :key="i" class="drag-list"
                                    :class="nature_checkedCities.includes(item.i)? 'drag-list-check':''">
                                    <td>
                                        <el-checkbox-group v-model="nature_checkedCities"
                                                           @change="nature_handleCheckedCitiesChange">
                                            <el-checkbox :label="item.i">{{i+1}}</el-checkbox>
                                        </el-checkbox-group>
                                    </td>
                                    <td>
                                        {{item.n}}
                                    </td>
                                    <td>
                                        <span v-for="(ite,i) in newmerchandise.customprop[i].ns"
                                              :key="i">{{ite}}；</span>

                                    </td>
                                </tr>
                                <tr class="drag-list" v-if="newmerchandise.customprop.length<1">
                                    <td class="nodata">
                                        <img src="../../../../../assets/img/wu.png" alt="">
                                        <div class="hint">暂无数据</div>
                                    </td>
                                </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
        </el-form>-->
        <span slot="footer" class="dialog-footer">
          <el-button @click="QuantityProduction = false">取消</el-button>
          <el-button type="primary" @click="NewPayChannel">确认</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 添加自定义属性 编辑 -->
    <div class="user-defined" v-show="custompropertyny">
      <el-dialog
        :title="addcompileproperty?'添加自定义属性':'编辑自定义属性'"
        @close="custompropertyny = false"
        :visible.sync="custompropertyny"
        :close-on-click-modal="false"
      >
        <div class="explain">说明：输入属性名称和属性值！例如属性：颜色；属性值：白色、红色；至少要有一个属性值！</div>
        <el-form label-position="left">
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>属性名：
              </div>
              <el-input
                v-model="attrs.n"
                placeholder="请输入属性名称"
                class="controlling"
                ref="selese"
                :class="form_rule_msg_name_custom?'error':''"
                @blur="validator('name_custom')"
              />
              <div class="cwts">{{form_rule_msg_name_custom}}</div>
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>属性值：
              </div>
              <div class="attribute">
                <div v-for="(item,i) in attrs.ns" :key="i">
                  <el-input
                    v-model="attrs.ns[i]"
                    placeholder="请输入属性值"
                    ref="selectsse"
                    :class="form_rule_msg_val_custom?'error':''"
                    @blur="validator('val_custom', attrs.ns[0])"
                  />
                  <icon-button
                    v-show="attrs.ns.length != 1"
                    @click.native="attrs.ns.splice(i,1)"
                    style="margin: 0px 8px;"
                    text="批量删除"
                    img="btn_delete.png"
                    colors="#6B2830"
                    bjcolors="#491E24"
                  ></icon-button>
                  <icon-button
                    v-show="attrs.ns.length == i+1"
                    @click.native="xinz"
                    style="margin: 0px 8px;"
                    text="新增"
                    img="btn_add.png"
                    colors="#f5f5f5"
                  ></icon-button>
                  <div class="cwts" v-show="i == 0">{{form_rule_msg_val_custom}}</div>
                </div>
              </div>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="custompropertyny = false">取消</el-button>
          <el-button v-show="addcompileproperty" type="primary" @click="addnature">新建</el-button>
          <el-button v-show="!addcompileproperty" type="primary" @click="compilenature">保存</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 编辑物料 -->
    <div class="dialogPrinter" v-show="redact">
      <el-dialog
        title="编辑物料"
        :visible.sync="redact"
        @close="gaunbbjym"
        :close-on-click-modal="false"
      >
        <!-- <div class="biaot">基本属性</div> -->
        <!-- <div class="needattention">注意：编辑后需要点击保存更改才能修改成功</div> -->
        <el-form label-position="left">
          <div class="fenge">
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>物料名称：
                </div>
                <el-input
                  v-model="compileMaterial.name"
                  placeholder="请输入物料名称"
                  ref="selectsse"
                  class="controlling"
                  :class="form_rule_msg_name?'error':''"
                  @blur="validator('name_edit')"
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
                >{{compileMaterial.phoneticize}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>物料空瓶回收：
                </div>
                <el-radio v-model="compileMaterial.rtn_bottle" label="1">有</el-radio>
                <el-radio v-model="compileMaterial.rtn_bottle" label="2">无</el-radio>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>物料单位：
                </div>
                <!-- <div style="display: flex;justify-content: space-between;width: 1070px;"> -->
                <el-select
                  v-model="compileMaterial.specification"
                  placeholder="请选择物料规格"
                  class="controlling"
                >
                  <el-option
                    v-for="each in compileMaterial.ficati"
                    :key="each.id"
                    :label="each.n"
                    :value="each.id"
                  ></el-option>
                </el-select>
                <!-- <el-button type="primary" size="medium" @click="SaveChangesBasics">保存更改</el-button> -->
                <!-- </div> -->
              </div>
            </div>
          </div>
          <!-- <div class="fenge">
                        <div class="compatibil">
                            <div class="compatibility">
                                <div class="mandatory">
                                    <span class="reqfieldsd">*</span>物料单位：
                                </div>
                                <div class="Materialunit">
                                    <div class="rial-unit">
                                        <icon-button @click.native="addunitpopup" text="新增" img="btn_add.png"
                                                     colors="#f5f5f5"></icon-button>
                                        <icon-button @click.native="deleteunit" text="删除" img="btn_delete.png" colors="#6B2830"
                                                     bjcolors="#491E24"></icon-button>
                                        <div class="miaos">【如物料有多种单位；例如支、箱等，则需要将不同的单位都添加；】</div>
                                    </div>
                                    <table class="Mater-unit">
                                        <thead class="mmodity">
                                        <tr>
                                            <th>
                                                <el-checkbox :indeterminate="compile_isIndeterminate"
                                                             v-model="compile_checkAll"
                                                             @change="compile_handleCheckAllChange">行号
                                                </el-checkbox>
                                            </th>
                                            <th>单位</th>
                                            <th>比例</th>
                                            <th>默认采购价</th>
                                            <th>默认销售价</th>
                                            <th>操作</th>
                                        </tr>
                                        </thead>
                                        <tbody class="limiting" :style="{
                                            'width':compileMaterial.Materialunit.length>4?'calc(100% + 6px)':'calc(100% + 6px)',
                                            'border-bottom':compileMaterial.Materialunit.length<1?'0px':''}">
                                        <tr v-for="(item,i) in this.compileMaterial.Materialunit" :key="i"
                                            class="drag-list"
                                            :class="compile_checkedCities.includes(item.lineid)? 'drag-list-check':''">
                                            <td>
                                                <el-checkbox-group v-model="compile_checkedCities"
                                                                   @change="compile_handleCheckedCitiesChange">
                                                    <el-checkbox :label="item.lineid">{{i+1}}</el-checkbox>
                                                </el-checkbox-group>
                                            </td>
                                            <td>
                                                <el-select :disabled="compileMaterial.Materialunit[i].id!=''"
                                                           v-model="compileMaterial.Materialunit[i].id"
                                                           placeholder="请选择物料单位">
                                                    <el-option v-for="each in compileMaterial.ListUnits" :key="each.id"
                                                               :label="each.n" :value="each.id"></el-option>
                                                </el-select>
                                            </td>
                                            <td>{{item.ratio}}</td>
                                            <td>
                                                <el-input :disabled="!item.savecompile" v-model="item.bp"
                                                          placeholder="输入价格"/>
                                            </td>
                                            <td>
                                                <div v-show="item.ut == 2">—</div>
                                                <el-input :disabled="!item.savecompile" v-show="item.ut == 1"
                                                          v-model="item.sp" placeholder="输入价格"/>
                                            </td>
                                            <td>
                                                <div class="lans" v-show="item.savecompile" @click="saveline(item,i)">
                                                    保存
                                                </div>
                                                <div class="lans" v-show="!item.savecompile" @click="compileline(item)">
                                                    编辑
                                                </div>

                                            </td>
                                        </tr>
                                        <tr class="drag-list" v-if="compileMaterial.Materialunit.length<1">
                                            <td class="nodata">
                                                <img src="../../../../../assets/img/wu.png" alt="">
                                                <div class="hint">暂无数据</div>
                                            </td>
                                        </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
          </div>-->
        </el-form>
        <!-- <div class="biaot">扩展属性</div>
                <div class="fenge">
                    <div class="annkz">
                        <icon-button @click.native="addpropertyedit" style="margin: 0px 8px;" text="新增" img="btn_add.png"
                                     colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="compileaddcroperty" style="margin: 0px 8px;" text="编辑" img="btn_edit.png"
                                     colors="#f5f5f5"></icon-button>
                        <icon-button @click.native="delteperty" style="margin: 0px 8px;" text="批量删除" img="btn_delete.png"
                                     colors="#6B2830" bjcolors="#491E24"></icon-button>
                    </div>
                    <el-form label-position="left">
                        <div class="compatibil">
                            <div class="compatibility">
                                <span class="required"></span>
                          <div class="compa-tib">&emsp;自定义属性&emsp;<br>（最多添加6个）</div>
                                <div class="mandatory">
                                    <span class="reqfieldsd"></span>自定义属性：<br>（最多添加6个）
                                </div>
                                <table class="extend-unit" style="margin-left: 10px;">
                                    <thead class="mmodity">
                                    <tr>
                                        <th>
                                            <el-checkbox :indeterminate="comperty_isIndeterminate"
                                                         v-model="comperty_checkAll"
                                                         @change="comperty_handleCheckAllChange">行号
                                            </el-checkbox>
                                        </th>
                                        <th>属性名称</th>
                                        <th>属性值</th>
                                    </tr>
                                    </thead>
                                    <tbody class="limiting" :style="{
                                    'width':compileMaterial.customprop.length>4?'calc(100% + 6px)':'calc(100% + 6px)',
                                    'border-bottom':compileMaterial.customprop.length<1?'0px':''}">
                                    <tr v-for="(item,i) in compileMaterial.customprop" :key="i" class="drag-list"
                                        :class="comperty_checkedCities.includes(item.id)? 'drag-list-check':''">
                                        <td>
                                            <el-checkbox-group v-model="comperty_checkedCities"
                                                               @change="comperty_handleCheckedCitiesChange">
                                                <el-checkbox :label="item.id">{{i+1}}</el-checkbox>
                                            </el-checkbox-group>
                                        </td>
                                        <td>
                                            {{item.n}}
                                        </td>
                                        <td>
                                            <span v-for="(ite) in compileMaterial.customprop[i].ts" :key="ite.id">{{ite.n}}；</span>
                                        </td>
                                    </tr>
                                    <tr class="drag-list" v-if="compileMaterial.customprop.length<1">
                                        <td class="nodata">
                                            <img src="../../../../../assets/img/wu.png" alt="">
                                            <div class="hint">暂无数据</div>
                                        </td>
                                    </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </el-form>
        </div>-->
        <span slot="footer" class="dialog-footer">
          <!-- <el-button @click="gaunbbjym">关闭</el-button> -->
          <el-button @click="gaunbbjym">取消</el-button>
          <el-button type="primary" @click="SaveChangesBasics">确认</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 添加物料单位 -->
    <div class="editaddunit" v-show="compileAddDialog">
      <el-dialog
        title="添加物料单位"
        :visible.sync="compileAddDialog"
        @close="compileAddDialog = false"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>单位：
              </div>
              <el-select v-model="addbjpopup.unitid" placeholder="请选择物料单位" class="controlling">
                <el-option
                  v-for="each in compileMaterial.ListUnits"
                  :key="each.id"
                  :label="each.n"
                  :value="each.id"
                ></el-option>
              </el-select>
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>比例：
              </div>
              <div style="color:#40404e ;" class="controlling">{{addbjpopup.proportion}}</div>
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>默认采购价：
              </div>
              <el-input v-model="addbjpopup.purchase" placeholder="默认采购价" class="controlling" />
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>默认销售价：
              </div>
              <el-input
                v-show="addbjpopup.ut == 1"
                v-model="addbjpopup.market"
                placeholder="默认销售价"
                class="controlling"
              />
              <div class="requimeiytgy controlling" v-show="addbjpopup.ut != 1">------</div>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="compileAddDialog = false">取消</el-button>
          <el-button type="primary" @click="compileaddMaterialunit">添加</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 添加自定义属性 -->
    <div class="user-defined" v-show="controlproperty">
      <el-dialog
        title="添加自定义属性"
        :visible.sync="controlproperty"
        @close="controlproperty = false"
        :close-on-click-modal="false"
      >
        <div class="explain">说明：输入属性名称和属性值！例如属性：颜色；属性值：白色、红色；至少要有一个属性值！</div>
        <el-form label-position="left">
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>属性名：
              </div>
              <el-input
                v-model="attrs.n"
                placeholder="请输入属性名称"
                class="controlling"
                ref="slfs"
                :class="form_rule_msg_name_custom?'error':''"
                @blur="validator('name_custom')"
              />
              <div class="cwts">{{form_rule_msg_name_custom}}</div>
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>属性值：
              </div>
              <div class="attribute">
                <div v-for="(item,i) in attrs.ns" :key="i">
                  <el-input
                    v-model="attrs.ns[i]"
                    placeholder="请输入属性值"
                    ref="selectsse"
                    :class="form_rule_msg_val_custom?'error':''"
                    @blur="validator('val_custom', attrs.ns[0])"
                  />
                  <icon-button
                    v-show="attrs.ns.length != 1"
                    @click.native="attrs.ns.splice(i,1)"
                    style="margin: 0px 8px;"
                    text="批量删除"
                    img="btn_delete.png"
                    colors="#6B2830"
                    bjcolors="#491E24"
                  ></icon-button>
                  <icon-button
                    v-show="attrs.ns.length == i+1"
                    @click.native="xinz"
                    style="margin: 0px 8px;"
                    text="新增"
                    img="btn_add.png"
                    colors="#f5f5f5"
                  ></icon-button>
                  <div class="cwts" v-show="i == 0">{{form_rule_msg_val_custom}}</div>
                </div>
              </div>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="controlproperty = false">取消</el-button>
          <el-button type="primary" @click="addnatureproperty">新建</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 编辑自定义属性  -->
    <div class="user-defined" v-show="compiletrolprope">
      <el-dialog
        title="编辑自定义属性"
        :visible.sync="compiletrolprope"
        @close="compiletrolprope = false"
        :close-on-click-modal="false"
      >
        <div class="explain">说明：输入属性名称和属性值！例如属性：颜色；属性值：白色、红色；至少要有一个属性值！</div>
        <el-form label-position="left">
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>属性名：
              </div>
              <el-input
                v-model="compilecustomsx.nr.n"
                placeholder="请输入属性名称"
                class="controlling"
                ref="slfs"
                :class="form_rule_msg_name_custom?'error':''"
                @blur="validator('name_custom_compilecustomsx')"
              />
              <div class="cwts">{{form_rule_msg_name_custom}}</div>
            </div>
          </div>
          <div class="compatibil">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>属性值：
              </div>
              <div class="attribute">
                <div v-for="(item,i) in compilecustomsx.nr.ts" :key="i">
                  <el-input
                    v-model="item.n"
                    placeholder="请输入属性值"
                    ref="selectsse"
                    :class="form_rule_msg_val_custom?'error':''"
                    @blur="validator('val_custom_compilecustomsx', item.n)"
                  />
                  <icon-button
                    v-show="compilecustomsx.nr.ts.length != 1"
                    @click.native="delecpilecuspperty(item.id,i)"
                    style="margin: 0px 8px;"
                    text="批量删除"
                    img="btn_delete.png"
                    colors="#6B2830"
                    bjcolors="#491E24"
                  ></icon-button>
                  <icon-button
                    v-show="compilecustomsx.nr.ts.length == i+1"
                    @click.native="addcpilecuspperty"
                    style="margin: 0px 8px;"
                    text="新增"
                    img="btn_add.png"
                    colors="#f5f5f5"
                  ></icon-button>
                  <div class="cwts" v-show="i == 0">{{form_rule_msg_val_custom}}</div>
                </div>
              </div>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="compiletrolprope = false">取消</el-button>
          <el-button type="primary" @click="customcompilenature">保存</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 批量导入  -->
    <div class="tolead" v-show="batchImport">
      <el-dialog
        :class="{'choose': chooseTemplateStatus==1}"
        :title="chooseTemplateStatus==1?'批量导入':chooseTemplateStatus==2?'批量导入物料':'批量导入物料及收银商品'"
        :visible.sync="batchImport"
        @close="batchImport = false"
        :close-on-click-modal="false"
      >
        <div
          v-if="chooseTemplateStatus==1"
          style="margin-top:20px;color:rgb(217, 217, 217)"
          layout="row"
          layout-align="space-around center"
        >
          <div
            class="m-t-3"
            style="color:#438dfd;cursor:pointer;"
            @click="chooseTemplateStatus=2"
          >仅导入物料</div>
          <div
            class="m-t-3"
            style="color:#438dfd;cursor:pointer;"
            @click="chooseTemplateStatus=3"
          >同时导入物料和收银商品</div>
        </div>
        <div v-else style="margin-top: 20px;">
          <el-upload
            class="upload-demo"
            drag
            :action="http"
            :headers="tk"
            :on-success="succeed"
            :on-error="error"
            :on-progress="progress"
            :with-credentials="true"
            ref="ToLeadItem"
            name="impfile"
            multiple
          >
            <div style="margin: 35px 0 10px;">
              <img style="height: 70px;width: 67px;" src="../../../../../assets/img/upload_file.png" alt />
            </div>
            <div class="el-upload__text" style="color: #40404e;">
              将文件拖到此处，或
              <em>点击上传</em>
            </div>
            <div class="el-upload__tip" slot="tip" style="color: #8C8C8C;">只支持上传xlsx文件</div>
          </el-upload>
          <div
            style="color: #7298FF; text-align: center;margin: 5px 0;"
            @click="DownloadTemplate"
          >点击下载模板</div>
          <div
            style="color: #FF2F4B; text-align: center;"
          >！导入后将新增物料{{chooseTemplateStatus==2?'':'和收银商品'}}</div>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="batchImport = false">取消</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 反馈信息 -->
    <div class="feedback" v-show="feedback">
      <el-dialog
        title="导入单品"
        :visible.sync="feedback"
        @close="resumes"
        :close-on-click-modal="false"
      >
        <div class="feedback-check">
          共导入{{ImportData.length}}条数据，成功处理{{dataAnalysis}}条，可选择成功处理的正常数据导入或根据反馈信息修改后重新导入
          <br />*号标识代表必填项，没有则为选填
          <br />此序号对应文档中序号
        </div>
        <div class="feedback-check">反馈信息:</div>
        <div class="juzhong">
          <table class="table">
            <thead>
              <tr>
                <th>
                  <el-checkbox
                    :indeterminate="isIndeterminatedata"
                    v-model="checkAlldata"
                    @change="handleCheckAllChangedata"
                  >序号 1,2</el-checkbox>
                </th>
                <th>物料名称</th>
                <th>{{chooseTemplateStatus==3?'物料':''}}一级分类</th>
                <th>{{chooseTemplateStatus==3?'物料':''}}二级分类</th>
                <th>物料单位</th>
                <th style="width:100px;">空瓶回收</th>
                <th v-if="chooseTemplateStatus==3" style="width:100px;">收银商品名称</th>
                <th v-if="chooseTemplateStatus==3" style="width:120px;">收银商品一级分类</th>
                <th v-if="chooseTemplateStatus==3" style="width:120px;">收银商品二级分类</th>
                <th v-if="chooseTemplateStatus==3" style="width:120px;">收银商品类型</th>
                <th v-if="chooseTemplateStatus==3" style="width:100px">收银商品价格</th>
                <th v-if="chooseTemplateStatus==3" style="width:120px">收银商品会员价</th>
                <th style="width:200px;">结果反馈</th>
              </tr>
            </thead>
            <tbody
              :style="{
                'width':ImportData.length>4?'calc(100% + 6px)':'100%',
                'border-bottom':ImportData.length<1?'0px':''}"
            >
              <tr v-for="(item, i) in ImportData" :key="item.id" class="drag-lists">
                <td>
                  <el-checkbox-group
                    v-model="checkedCitiesdata"
                    @change="handleCheckedCitiesChangedata"
                  >
                    <el-checkbox :disabled="whetherForbidden[i]" :label="item.ids">{{i+3}}</el-checkbox>
                  </el-checkbox-group>
                </td>
                <td>{{item.names}}</td>
                <td>{{item.mat_one_cate_names}}</td>
                <td>{{item.mat_two_cate_names}}</td>
                <td>{{item.unit_names}}</td>
                <td style="width:100px;">{{item.rtn_bottle}}</td>
                <td v-if="chooseTemplateStatus==3" style="width:100px;">{{item.prd_names}}</td>
                <td v-if="chooseTemplateStatus==3" style="width:140px;">{{item.prd_one_cate_names}}</td>
                <td v-if="chooseTemplateStatus==3" style="width:120px;">{{item.prd_two_cate_names}}</td>
                <td v-if="chooseTemplateStatus==3" style="width:120px;">{{item.prd_types }}</td>
                <td v-if="chooseTemplateStatus==3" style="width:100px">{{item.prices}}</td>
                <!-- <td v-if="chooseTemplateStatus==3" style="width:100px;">{{item.member_prices}}</td> -->
                <td style="width:200px;" layout="row" layout-align="center center">
                  <div
                    v-if="!whetherForbidden[i]"
                    style="color: #2170ff"
                  >
                    正常数据
                    <span v-for="(result, si) in item.err_msgs" :key="si">{{result}}</span>
                  </div>
                  <div
                    v-else
                    style="color: #FF2F4B"
                    v-for="(result, si) in item.err_msgs"
                    :key="si"
                  >{{result}}</div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="resumes">取消</el-button>
          <el-button type="primary" @click="importDataHandle">导入</el-button>
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
      >
        <div class="wwent" v-show="cwsm.cs.length>0">
          <span>以下对象存在依赖，需同步设置为{{srnr | pand}}</span>
          <characters-button
            @click.native="synchronizon"
            :disaed="kzsfjy"
            colors="#f5f5f5"
            :wz="`同步${srnr}`"
          ></characters-button>
        </div>
        <div class="wentlb" v-show="cwsm.cs.length>0">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>说明</th>
                <th>处理结果</th>
              </tr>
            </thead>
            <tbody class="limiting" :style="{'width':cwsm.cs.length>6?'calc(100% + 6px)':'100%'}">
              <tr v-for="(item,i) in cwsm.cs" :key="i" class="drag-list">
                <td>{{i+1}}</td>
                <td>
                  <ellipsis-tooltip :text="item.r || '-----'"></ellipsis-tooltip>
                </td>
                <td v-show="item.jg == '成功'" style="color: #00BC72;">{{item.jg}}</td>
                <td v-show="item.jg == '---'">{{item.jg}}</td>
                <td v-show="item.jg == '失败'" style="color: #E13B50;">{{item.jg}}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="wwent" v-show="cwsm.ns.length>0">以下对象存在依赖，需人工处理依赖</div>
        <div class="wentlb danykz" v-show="cwsm.ns.length>0">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>说明</th>
              </tr>
            </thead>
            <tbody class="limiting" :style="{'width':cwsm.ns.length>6?'calc(100% + 6px)':'100%'}">
              <tr v-for="(item,i) in cwsm.ns" :key="i" class="drag-list">
                <td>{{i+1}}</td>
                <td>
                  <ellipsis-tooltip :text="item || '-----'"></ellipsis-tooltip>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogFible = false">关闭</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 批量设置二级分类 -->
    <setTwoSecondCategory
      :showDrawer="setSecondCategory.showDrawer"
      @showOrHideSetSecondCategoryHandle="showOrHideSetSecondCategoryHandle"
      @submitSecondCategoryHandle="submitSecondCategoryHandle"
    />
  </div>
</template>
<script>
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import { projectName, projectConfig } from '@/utils/config/projectConfig.js'
import { sessionStorage, localStorage } from '@/utils/common/storage'
import setTwoSecondCategory from './setTwoCategory.vue'
import eventVue from '@/utils/eventVue';

export default {
  data() {
    return {
      List: [], //全部内容
      checkAll: false, //全部选中触发
      checkedCities: [], //已选择内容
      isIndeterminate: false, //全选或者全不选

      classify: {
        stairSecond: [], //一级二级全部内容分类
        stairfl: 0, //一级分类
        Secondfl: 0 //二级分类
      }, //分类
      pdddymy: false, //判断有没有二级分类
      merchandise: [], //物料
      QuantityProduction: false, //控制新增物料的打开关闭
      newmerchandise: {
        name: "", //物料名称
        phoneticize: "", //拼音
        specification: "", //物料规格
        rtn_bottle: "2", // 1 有 2 无
        Materialunit: [], //物料单位
        ficati: [], //规格列表
        ListUnits: [], //单位列表
        customprop: [] //自定义属性列表
      }, //新建物料

      unit_isIndeterminate: false, // 物料单位全选或者全不选
      unit_checkAll: false, //物料单位全部选中触发
      unit_checkedCities: [], //物料单位已选择内容
      custompropertyny: false, //自定义属性是否显示
      attrs: {}, //添加物料属性
      nature_isIndeterminate: false, // 物料属性全选或者全不选
      nature_checkAll: false, //物料属性全部选中触发
      nature_checkedCities: [], //物料属性已选择内容
      addcompileproperty: true, //判断是编辑还是新建

      redact: false, //编辑商品
      compileMaterial: {
        name: "", //物料名称
        phoneticize: "", //拼音
        specification: "", //物料规格
        rtn_bottle: "2", // 1 有 2 无
        Materialunit: [], //物料单位
        ficati: [], //规格列表
        ListUnits: [], //单位列表

        customprop: [] //自定义属性列表
      }, //编辑物料内容
      compile_isIndeterminate: false, // 物料单位全选或者全不选
      compile_checkAll: false, //物料单位全部选中触发
      compile_checkedCities: [], //物料单位已选择内容
      compileAddDialog: false, // 控制编辑新增弹窗
      addbjpopup: {
        unitid: "", //单位id
        proportion: "", //比例
        purchase: "", //默认采购价
        market: "", //默认销售价
        ut: "1" //控制
      }, //新增物理单位单位

      comperty_isIndeterminate: false, // 编辑 物料属性全选或者全不选
      comperty_checkAll: false, // 编辑 物料属性全部选中触发
      comperty_checkedCities: [], // 编辑 物料属性已选择内容
      controlproperty: false, //控制 新增 物料属性添加自定义属性的弹窗
      compiletrolprope: false, //控制  物料属性编辑自定义属性的弹窗
      compilecustomsx: {
        nr: {}, //内容
        delid: [], //删除的id
        addname: [], //在后面新增的属性明细项名
        chg: [] //修改的
      }, // 编辑  编辑自定义属性

      chooseTemplateStatus: 1, // 选择批量导入  1：选择导入类型  2：仅仅导入物料  3：同时导入物料和收银商品
      batchImport: false, //控制批量导入显示与否
      ImportData: [], //所有的商品导入信息
      feedback: false, //控制反馈显示与否
      dataAnalysis: "", //成功处理多少条数据
      tk: { tk: localStorage.getItem("tk"), tt: '64' }, //token
      whetherForbidden: [], //判断是否禁用

      checkAlldata: false, //全部选中触发
      checkedCitiesdata: [], //已选择内容
      isIndeterminatedata: false, //全选或者全不选

      id: "", //二级分类id

      dialogFible: false, //控制错误2是否显示
      srnr: "", //文案
      cwsm: {
        ns: [], //不可操作列表
        cs: [] //可一键操作列表
      }, //错误2说明
      kzsfjy: false, //控制同步按钮是否禁用
      windowWidt: document.documentElement.clientWidth, //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight, //实时屏幕高度
      MaxHeight: 0, //滚动高度
      MaxNumber: 0, //最大个数

      form_rules: ["name"],
      form_rules_edit: ["name_edit"],
      form_rules_custom: ["name_custom", "val_custom"],
      form_rules_custom_compilecustomsx: [
        "name_custom_compilecustomsx",
        "val_custom_compilecustomsx"
      ],
      form_rule_msg_name: "",
      form_rule_msg_name_custom: "",
      form_rule_msg_val_custom: "",

      flag: false,
    
      
      /*批量设置二级分类 */
      setSecondCategory: {
        showDrawer: false
      }
    };
  },
  mounted() {
    this.refresh(this.$route.params.id);
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
    eventVue.$on('reloadTableData', () => {
      this.refresh(this.$route.params.id);
    })
  },
  beforeDestroy() {
    eventVue.$off('reloadTableData')
  },
  filters: {
    pand: function(v) {
      if (v == "置为无效") {
        return "无效";
      } else if (v == "置为有效") {
        return "有效";
      } else if (v == "批量删除") {
        return "删除";
      }
    }
  },
  components: {
    EllipsisTooltip,
    IconButton,
    CharactersButton,
    setTwoSecondCategory
  },

  methods: {
    //滚动条监听
    changeFlag(flag) {
      this.flag = flag;
    },
    // 左右滚动条滚动同步
    sysHandleScroll() {
      if (!this.flag) {
        this.$refs.externalForm.scrollTop = this.$refs.systemForm.scrollTop;
      }
    },
    exterHandleScroll() {
      if (this.flag) {
        this.$refs.systemForm.scrollTop = this.$refs.externalForm.scrollTop;
      }
    },
    // form表单检测
    validator(val, num) {
      console.log(val);
      switch (val) {
        case "name":
          if (this.newmerchandise.name == "") {
            this.form_rule_msg_name = "请输入物料名称";
          } else if (this.$overall.character(this.newmerchandise.name) > 60) {
            this.form_rule_msg_name = "输入文字长度超过30";
          } else {
            this.form_rule_msg_name = "";
          }
          break;
        case "name_edit":
          if (this.compileMaterial.name == "") {
            this.form_rule_msg_name = "请输入物料名称";
          } else if (this.$overall.character(this.compileMaterial.name) > 60) {
            this.form_rule_msg_name = "输入文字长度超过30";
          } else {
            this.form_rule_msg_name = "";
          }
          break;
        case "name_custom":
          if (this.attrs.n == "") {
            this.form_rule_msg_name_custom = "请输入属性名称";
          } else if (this.$overall.character(this.attrs.n) > 20) {
            this.form_rule_msg_name_custom = "输入文字长度超过10";
          } else {
            this.form_rule_msg_name_custom = "";
          }
          break;
        case "val_custom":
        case "val_custom_compilecustomsx":
          if (!num) {
            this.form_rule_msg_val_custom = "请输入属性值";
          } else if (this.$overall.character(num) > 20) {
            this.form_rule_msg_val_custom = "输入文字长度超过10";
          } else {
            this.form_rule_msg_val_custom = "";
          }
          break;
        case "name_custom_compilecustomsx":
          if (!this.compilecustomsx.nr.n) {
            this.form_rule_msg_name_custom = "请输入属性名称";
          } else if (this.$overall.character(this.compilecustomsx.nr.n) > 20) {
            this.form_rule_msg_name_custom = "输入文字长度超过10";
          } else {
            this.form_rule_msg_name_custom = "";
          }
          break;
      }
    },
    // 滚动最大高度
    RollMaxHeight(i) {
      var s = i - 48 - 60 - 55 - 37;
      this.MaxHeight = s;
      this.MaxNumber = Math.floor(s / 37);
      console.log(this.MaxNumber);
      // console.log(i);
    },
    
    // 修改分类
    editTwoCategoryHandle(){
      if(this.checkedCities.length == 0) return this.$message.warning('请选择需要修改分类的商品')
      this.showOrHideSetSecondCategoryHandle();
    },
    // 显示或隐藏修改商品分类
    showOrHideSetSecondCategoryHandle(){
      this.setSecondCategory.showDrawer = !this.setSecondCategory.showDrawer;
    },
    // 提交修改商品分类
    async submitSecondCategoryHandle(secondId){
      const params = {
        mat_ids: this.checkedCities, //    []int64   待操作商品Id
        two_cate_id: secondId * 1, // int64    目标二级分类Id
      }

      try {
        const res = await this.$api.ERP.mat.reqSetSecondCategory(params);
        if (res.code == 1){
          this.$message.success('操作成功');
          this.showOrHideSetSecondCategoryHandle();
          this.refresh(+this.$route.params.id, true);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('批量设置二级分类失败', error)
      }
    },

    // 刷新物料
    refresh(id, reset = false) {
      this.$api.ERP.mat.requestmatlist({ id: Number(id) }).then(res => {
        console.log(res);
        if (res.code == 1) {
          console.log(res.data);
          this.merchandise = res.data || [];
          if(reset){
            this.checkedCities = [];
            this.checkAll = false;
            this.isIndeterminate = false;
          }
          var s = [];
          for (const iterator of this.merchandise) {
            s.push(iterator.id);
          }
          for (var i = 0; i < this.checkedCities.length; i++) {
            if (s.indexOf(this.checkedCities[i]) == -1) {
              this.checkedCities.splice(i, 1);
            }
          }
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 为空
    weik() {
      this.isIndeterminate = false;
      this.checkAll = false;
      this.checkedCities = [];
    },
    // 控制全选或者全不选
    handleCheckAllChange(val) {
      if (val) {
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
    // 打开新增物料
    VolumeProduction() {
      this.form_rule_msg_name = "";
      this.$api.ERP.mat
        .requestmatget({
          id: 0
          // one_cate_id:this.classify.stairSecond[this.classify.stairfl].id
        })
        .then(res => {
          console.log(res);
          this.newmerchandise.ficati = (res.data.units || []).filter(
            item => item.s == 1
          ); //res.data.mat_spec_dfn
          this.newmerchandise.ListUnits = res.data.mat_unit_dfn;
          this.newmerchandise.Materialunit = [
            {
              id: "", //单位id
              ratio: "", //比例
              bp: "", //采购价
              sp: "", //销售价
              i: 1, //索引
              ut: 1 //类型单位
            }
          ];
          this.newmerchandise.name = "";
          this.newmerchandise.phoneticize = "";
          this.newmerchandise.specification = "";
          this.newmerchandise.customprop = [];
          this.QuantityProduction = true;
          this.unit_isIndeterminate = false;
          this.unit_checkAll = false;
          this.unit_checkedCities = [];

          this.$nextTick(() => {
            //次要代码
            this.$refs.xidhf.focus();
          });
        });
    },
    // 添加属性值
    xinz() {
      this.attrs.ns.push("");
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse[this.$refs.selectsse.length - 1].focus();
        console.log(this.$refs.selectsse);
      });
    },
    // 新增物料单位
    addMaterialunit() {
      this.newmerchandise.Materialunit.push({
        id: "", //单位id
        ratio: "", //比例
        bp: "", //采购价
        sp: "", //销售价
        i: this.newmerchandise.Materialunit.length + 1, //索引
        ut: 1
      });
      console.log(this.newmerchandise.Materialunit);
    },
    // 删除物料单位
    deleteMaterialunit() {
      console.log(this.unit_checkedCities);
      for (const key in this.newmerchandise.Materialunit) {
        for (const ke in this.unit_checkedCities) {
          if (
            this.unit_checkedCities[ke] ==
            this.newmerchandise.Materialunit[key].i
          ) {
            console.log(this.newmerchandise.Materialunit[key].i);
            this.newmerchandise.Materialunit.splice(key, 1);
          }
        }
      }
      for (const key in this.newmerchandise.Materialunit) {
        this.newmerchandise.Materialunit[key].i = key * 1 + 1;
      }
      this.unit_isIndeterminate = false;
      this.unit_checkAll = false;
      this.unit_checkedCities = [];
    },
    // 物料单位控制全选或者全不选
    unit_handleCheckAllChange(val) {
      console.log(this.newmerchandise.Materialunit);
      if (val) {
        // console.log(this.merchandise);
        this.unit_checkedCities = [];
        for (const key in this.newmerchandise.Materialunit) {
          console.log(key);
          this.unit_checkedCities.push(key * 1 + 1);
        }
      } else {
        this.unit_checkedCities = [];
      }
      console.log(this.unit_checkedCities);
      this.unit_isIndeterminate = false;
    },
    // 物料单位控制单个选中
    unit_handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.unit_checkAll =
        checkedCount === this.newmerchandise.Materialunit.length;
      this.unit_isIndeterminate =
        checkedCount > 0 &&
        checkedCount < this.newmerchandise.Materialunit.length;
      // console.log(this.checkedCities);
    },
    // 打开添加自定义属性
    addproperty() {
      this.form_rule_msg_val_custom = "";
      this.form_rule_msg_name_custom = "";
      if (this.newmerchandise.customprop.length == 6) {
        this.$message({ message: "自定义属性最多添加6个", type: "error" });
      } else {
        this.addcompileproperty = true;
        this.custompropertyny = true;
        this.attrs = {
          n: "",
          ns: [""],
          i: this.newmerchandise.customprop.length + 1
        };
        this.$nextTick(() => {
          //次要代码
          this.$refs.selese.focus();
          console.log(this.$refs.selese);
        });
      }

      // this.newmerchandise.customprop.push()
    },
    // 添加自定义属性
    addnature() {
      this.form_rules_custom.map(item => {
        if (item == "val_custom") {
          this.validator(item, this.attrs.ns[0]);
        } else {
          this.validator(item);
        }
      });
      if (this.form_rule_msg_name_custom || this.form_rule_msg_val_custom)
        return;
      if (this.attrs.n == "" || this.attrs.ns[0] == "") {
        this.$message({ message: "请填写必填项", type: "error" });
      } else {
        var s = [];
        for (const key in this.attrs.ns) {
          if (this.attrs.ns[key] != "") {
            s.push(this.attrs.ns[key]);
          }
        }
        this.attrs.ns = s;
        console.log(this.attrs.ns);
        this.newmerchandise.customprop.push(this.attrs);
        this.attrs = {
          n: "",
          ns: [""],
          i: this.newmerchandise.customprop.length + 1
        };
        this.custompropertyny = false;
      }
    },
    // 编辑自定义属性
    compilenature() {
      this.form_rules_custom.map(item => {
        if (item == "val_custom") {
          this.validator(item, this.attrs.ns[0]);
        } else {
          this.validator(item);
        }
      });
      if (this.form_rule_msg_name_custom || this.form_rule_msg_val_custom)
        return;
      if (this.attrs.n == "" || this.attrs.ns[0] == "") {
        this.$message({ message: "请填写必填项", type: "error" });
        return;
      }
      this.newmerchandise.customprop[
        this.nature_checkedCities[0] - 1
      ] = this.attrs;
      this.custompropertyny = false;
    },
    // 删除自定义属性
    deleteproperty() {
      for (var i = 0; i < this.newmerchandise.customprop.length; i++) {
        for (var j = 0; j < this.nature_checkedCities.length; j++) {
          console.log(
            this.newmerchandise.customprop[i].i,
            this.nature_checkedCities[j]
          );
          if (
            this.newmerchandise.customprop[i].i == this.nature_checkedCities[j]
          ) {
            this.newmerchandise.customprop.splice(i, 1);
            i = i - 1;
          }
        }
      }
      for (const key in this.newmerchandise.customprop) {
        this.newmerchandise.customprop[key].i = key * 1 + 1;
      }

      console.log(this.nature_checkedCities);
      this.nature_isIndeterminate = false;
      this.nature_checkAll = false;
      this.nature_checkedCities = [];
    },
    // 添加物料的时候编辑自定义属性
    compilecustomproperty() {
      this.form_rule_msg_val_custom = "";
      this.form_rule_msg_name_custom = "";
      // console.log(this.nature_checkedCities);
      if (this.newmerchandise.customprop.length != 0) {
        if (this.nature_checkedCities.length == 1) {
          // console.log(this.newmerchandise.customprop[this.nature_checkedCities[0]-1]);
          this.attrs = JSON.parse(
            JSON.stringify(
              this.newmerchandise.customprop[this.nature_checkedCities[0] - 1]
            )
          );
          this.addcompileproperty = false;
          this.custompropertyny = true;

          this.$nextTick(() => {
            //次要代码
            this.$refs.selese.focus();
            //   console.log(this.$refs.selese);
          });
        } else {
          this.$message({ message: "请选择一个进行编辑", type: "error" });
        }
      } else {
        this.$message({
          message: "请添加一个自定义属性，选中后在编辑",
          type: "error"
        });
      }
    },
    // 物料单位控制全选或者全不选
    nature_handleCheckAllChange(val) {
      console.log(this.newmerchandise.customprop);
      if (val) {
        // console.log(this.merchandise);
        this.nature_checkedCities = [];
        for (const key in this.newmerchandise.customprop) {
          console.log(key);
          this.nature_checkedCities.push(key * 1 + 1);
        }
      } else {
        this.nature_checkedCities = [];
      }
      console.log(this.naturet_checkedCities);
      this.nature_isIndeterminate = false;
    },
    // 物料单位控制单个选中
    nature_handleCheckedCitiesChange(value) {
      console.log(value);
      let checkedCount = value.length;
      this.nature_checkAll =
        checkedCount === this.newmerchandise.customprop.length;
      this.nature_isIndeterminate =
        checkedCount > 0 &&
        checkedCount < this.newmerchandise.customprop.length;
      // console.log(this.checkedCities);
    },
    // 新增商品
    NewPayChannel() {
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      if (
        "" == this.newmerchandise.name &&
        this.newmerchandise.specification == "" &&
        this.newmerchandise.Materialunit.length == 0
      ) {
        this.$message({ message: "请填写必填项", type: "error" });
      } else {
        for (const key in this.newmerchandise.Materialunit) {
          if (this.newmerchandise.Materialunit[key].ut == 2) {
            this.newmerchandise.Materialunit[key].sp = "0";
          }
        }
        // console.log(this.newmerchandise.Materialunit);
        this.$api.ERP.mat
          .requestmatnew({
            name: this.newmerchandise.name,
            mat_one_cate_id: Number(localStorage.getItem("opentwo")),
            mat_two_cate_id: Number(localStorage.getItem("openthree")),
            name_py: this.newmerchandise.phoneticize,
            unit_id: this.newmerchandise.specification,
            rtn_bottle: this.newmerchandise.rtn_bottle * 1 // int   空瓶回收 1 回收 2 不回收
          })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.QuantityProduction = false;
              // console.log(res);
              this.refresh(this.$route.params.id);
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
              this.weik();
            } else if (res.code == 6) {
              this.$message({
                showClose: true,
                message: "创建成功，状态无效，" + res.msg,
                type: "warning"
              });
              this.weik();
              this.refresh(this.$route.params.id);
              this.QuantityProduction = false;
            } else {
              this.$message({ message: res.msg, type: "error" });
            }
          });
      }
    },
    // 打开编辑物料
    staircompile() {
      console.log(this.checkedCities);
      if (this.checkedCities.length == 1) {
        this.form_rule_msg_name = "";
        this.$api.ERP.mat
          .requestmatget({ id: this.checkedCities[0] })
          .then(res => {
            console.log(res);
            this.compileMaterial.ficati = (res.data.units || []).filter(
              item => item.s == 1
            ); //res.data.mat_spec_dfn
            this.compileMaterial.ListUnits = res.data.mat_unit_dfn;
            this.compileMaterial.Materialunit = [];
            for (const key in res.data.mat.mat_units) {
              this.compileMaterial.Materialunit.push({
                lineid: res.data.mat.mat_units[key].id, //行id
                id: res.data.mat.mat_units[key].ui, //单位id
                ratio: "", //比例
                bp: res.data.mat.mat_units[key].bp, //采购价
                sp: res.data.mat.mat_units[key].sp, //销售价\
                savecompile: false
              });
            }
            this.compileMaterial.name = res.data.mat.name;
            this.compileMaterial.phoneticize = res.data.mat.name_py;
            this.compileMaterial.rtn_bottle = res.data.mat.rtn_bottle.toString();
            this.compileMaterial.specification = res.data.mat.unit_id;
            this.compileMaterial.customprop = res.data.mat.mat_attrs || [];
            this.redact = true;
            this.unit_isIndeterminate = false;
            this.unit_checkAll = false;
            this.unit_checkedCities = [];
          });
      } else {
        this.$message({
          message: "请选择一个进行编辑",
          type: "warning"
        });
      }
    },
    // 编辑 物料单位控制全选或者全不选
    compile_handleCheckAllChange(val) {
      // console.log(this.compileMaterial.Materialunit);
      if (val) {
        // console.log(this.merchandise);
        this.compile_checkedCities = [];
        for (const key in this.compileMaterial.Materialunit) {
          console.log(this.compileMaterial.Materialunit[key].lineid);
          this.compile_checkedCities.push(
            this.compileMaterial.Materialunit[key].lineid
          );
        }
      } else {
        this.compile_checkedCities = [];
      }
      this.compile_isIndeterminate = false;
    },
    // 编辑 物料单位控制单个选中
    compile_handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.compile_checkAll =
        checkedCount === this.compileMaterial.Materialunit.length;
      this.compile_isIndeterminate =
        checkedCount > 0 &&
        checkedCount < this.compileMaterial.Materialunit.length;
      // console.log(this.checkedCities);
    },
    // 保存更改基础信息
    SaveChangesBasics() {
      this.form_rules_edit.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      this.$api.ERP.mat
        .requestmatchg({
          id: this.checkedCities[0],
          name: this.compileMaterial.name,
          mat_one_cate_id: Number(localStorage.getItem("opentwo")),
          mat_two_cate_id: Number(localStorage.getItem("openthree")),
          name_py: this.compileMaterial.phoneticize,
          unit_id: this.compileMaterial.specification,
          rtn_bottle: this.compileMaterial.rtn_bottle * 1 // int  空瓶回收 1 回收 2 不回收
        })
        .then(res => {
          // console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.gaunbbjym()
            this.refresh(this.$route.params.id);
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 只刷新物料单位信息
    refreshMaterialUnit() {
      // this.$api.ERP.mat.requestmatget_only_unit({id: this.checkedCities[0]}).then(res => {
      //   console.log(res);
      //   for (const key in res.data) {
      //     this.compileMaterial.Materialunit[key].bp = res.data[key].bp
      //     this.compileMaterial.Materialunit[key].sp = res.data[key].sp
      //     this.compileMaterial.Materialunit[key].lineid = res.data[key].id
      //     this.compileMaterial.Materialunit[key].id = res.data[key].ui
      //   }
      // })
    },
    // 编辑物料单位行
    compileline(i) {
      console.log(i);
      i.savecompile = true;
    },
    // 保存物料单位行
    saveline(item, i) {
      console.log(item);
      // if (this.compileMaterial.Materialunit[i].ut == 2) {
      //   this.compileMaterial.Materialunit[i].sp = '0.00'
      // }
      // this.$api.ERP.mat.requestmatchg_unit({
      //   id: this.checkedCities[0],
      //   mat_mat_unit_id: item.lineid,
      //   mat_unit_id: item.id,
      //   unit_buy_price: this.compileMaterial.Materialunit[i].bp,
      //   unit_sell_price: this.compileMaterial.Materialunit[i].sp
      // }).then(res => {
      //   console.log(res);
      //   if (res.code == 1) {
      //     item.savecompile = false
      //     this.refreshMaterialUnit()
      //     this.$message({showClose: true, message: "操作成功", type: 'success'})
      //   } else {
      //     this.$message.warning(res.msg)
      //   }
      // })
    },
    // 新增物料单位弹窗
    addunitpopup() {
      this.refreshMaterialUnit();
      this.compileAddDialog = true;
      this.addbjpopup = {
        unitid: "", //单位id
        proportion: "", //比例
        purchase: "", //默认采购价
        market: "", //默认销售价
        ut: "1" //控制
      };
      this.edit();
    },
    // 新增物料单位
    compileaddMaterialunit() {
      // console.log(this.addbjpopup.market==""?0:this.addbjpopup.marke);
      // addbjpopup
      // this.$api.ERP.mat.requestmatadd_unit({
      //   id: this.checkedCities[0],
      //   mat_unit_id: this.addbjpopup.unitid,
      //   unit_buy_price: this.addbjpopup.purchase,
      //   unit_sell_price: this.addbjpopup.market == "" ? '0' : this.addbjpopup.market,
      // }).then(res => {
      //   console.log(res);
      //   if (res.code == 1) {
      //     this.compileAddDialog = false
      //     this.refreshMaterialUnit()
      //     this.compileMaterial.Materialunit.push({
      //       ui: '',//单位id
      //       id: '',//行id
      //       ratio: '',//比例
      //       bp: '',//采购价
      //       sp: "",//销售价
      //       savecompile: false,
      //       ut: this.addbjpopup.ut
      //     })
      //     this.$message({showClose: true, message: "操作成功", type: 'success'})
      //   } else {
      //     this.$message.warning(res.msg)
      //   }
      // })
      // console.log(this.compileMaterial.Materialunit);
    },
    // 编辑 删除物料单位
    deleteunit() {
      // console.log(this.compile_checkedCities);
      // this.$api.ERP.mat.requestmatrm_unit({
      //   id: this.checkedCities[0],
      //   mat_mat_unit_ids: this.compile_checkedCities
      // }).then(res => {
      //   if (res.code == 1) {
      //     if (this.compileMaterial.Materialunit.length == this.compile_checkedCities.length) {
      //       this.compileMaterial.Materialunit.splice(0)
      //     } else {
      //       for (var i = 0; i < this.compileMaterial.Materialunit.length; i++) {
      //         for (var j = 0; j < this.compile_checkedCities.length; j++) {
      //           if (this.compile_checkedCities[j] == this.compileMaterial.Materialunit[i].lineid) {
      //             this.compileMaterial.Materialunit.splice(i, 1)
      //             i = i - 1
      //           }
      //         }
      //       }
      //     }
      //     this.compile_isIndeterminate = false// 物料单位全选或者全不选
      //     this.compile_checkAll = false//物料单位全部选中触发
      //     this.compile_checkedCities = []//物料单位已选择内容
      //     this.$message({showClose: true, message: "操作成功", type: 'success'})
      //   } else {
      //     this.$message.warning(res.msg)
      //   }
      //   console.log(res);
      // })
    },
    // 编辑 物料单位控制全选或者全不选
    comperty_handleCheckAllChange(val) {
      if (val) {
        // console.log(this.merchandise);
        this.comperty_checkedCities = [];
        for (const key in this.compileMaterial.customprop) {
          this.comperty_checkedCities.push(
            this.compileMaterial.customprop[key].id
          );
        }
      } else {
        this.comperty_checkedCities = [];
      }
      this.comperty_isIndeterminate = false;
    },
    // 编辑 物料单位控制单个选中
    comperty_handleCheckedCitiesChange(value) {
      // console.log(value);
      let checkedCount = value.length;
      this.comperty_checkAll =
        checkedCount === this.compileMaterial.customprop.length;
      this.comperty_isIndeterminate =
        checkedCount > 0 &&
        checkedCount < this.compileMaterial.customprop.length;
      // console.log(this.checkedCities);
    },
    // 只刷新物料属性信息
    refreshMaterialProperty() {
      // this.$api.ERP.mat.requestmatget_only_attr({id: this.checkedCities[0]}).then(res => {
      //   console.log(res.data);
      //   this.compileMaterial.customprop = res.data || []
      // })
    },
    // 打开添加自定义属性
    addpropertyedit() {
      this.form_rule_msg_val_custom = "";
      this.form_rule_msg_name_custom = "";
      console.log(this.compileMaterial.customprop);
      // if(this.compileMaterial.customprop){
      //     this.compileMaterial.customprop = []
      // }
      this.refreshMaterialProperty();
      console.log(this.compileMaterial.customprop);
      if (this.compileMaterial.customprop.length > 5) {
        this.$message({ message: "自定义属性已添加6个", type: "error" });
      } else {
        this.addcompileproperty = true;
        this.controlproperty = true;
        this.attrs = {
          n: "",
          ns: [""],
          i: this.compileMaterial.customprop.length + 1
        };
        this.$nextTick(() => {
          //次要代码
          this.$refs.slfs.focus();
        });
      }
    },
    // 添加自定义属性
    addnatureproperty() {
      // this.form_rules_custom.map(item => {
      //   if (item == "val_custom") {
      //     this.validator(item, this.attrs.ns[0])
      //   } else {
      //     this.validator(item)
      //   }
      // });
      // if (this.form_rule_msg_name_custom || this.form_rule_msg_val_custom) return;
      // if (this.attrs.n == '' && this.attrs.ns[0] == '') {
      //   this.$message({message: "请填写必填项", type: 'error',})
      // } else {
      //   this.$api.ERP.mat.requestmatadd_attr({
      //     id: this.checkedCities[0],
      //     attr_name: this.attrs.n,
      //     dtl_names: this.attrs.ns
      //   }).then(res => {
      //     console.log(res);
      //     if (res.code == 1) {
      //       this.controlproperty = false
      //       this.$message({showClose: true, message: "操作成功", type: 'success'})
      //       this.refreshMaterialProperty()
      //     } else {
      //       this.$message.warning(res.msg)
      //     }
      //   })
      // }
    },
    // 编辑自定义属性
    compileaddcroperty() {
      this.form_rule_msg_val_custom = "";
      this.form_rule_msg_name_custom = "";
      // console.log(this.compileMaterial.customprop);
      // console.log(this.comperty_checkedCities);
      if (this.compileMaterial.customprop.length != 0) {
        if (this.comperty_checkedCities.length == 1) {
          for (const key in this.compileMaterial.customprop) {
            if (
              this.compileMaterial.customprop[key].id ==
              this.comperty_checkedCities[0]
            ) {
              this.compilecustomsx.nr = JSON.parse(
                JSON.stringify(this.compileMaterial.customprop[key])
              );
              this.compiletrolprope = true;
              this.$nextTick(() => {
                //次要代码
                this.$refs.slfs.focus();
              });
            }
          }
        } else {
          this.$message({ message: "请选择一个进行编辑", type: "error" });
        }
      } else {
        this.$message({
          message: "请添加一个自定义属性，选中后在编辑",
          type: "error"
        });
      }
    },
    // 删除编辑自定义属性
    delecpilecuspperty(id, i) {
      console.log(id);
      this.compilecustomsx.nr.ts.splice(i, 1);

      if (id) {
        this.compilecustomsx.delid.push(id);
      }
    },
    // 增加编辑自定义属性
    addcpilecuspperty() {
      this.compilecustomsx.nr.ts.push({
        n: ""
      });
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse[this.$refs.selectsse.length - 1].focus();
        console.log(this.$refs.selectsse);
      });
    },
    // 保存编辑自定义属性
    customcompilenature() {
      this.form_rules_custom_compilecustomsx.map(item => {
        if (item == "val_custom_compilecustomsx") {
          this.validator(item, this.compilecustomsx.nr.ts[0].n);
        } else {
          this.validator(item);
        }
      });
      if (this.form_rule_msg_name_custom || this.form_rule_msg_val_custom)
        return;
      // console.log(this.comperty_checkedCities);
      this.compilecustomsx.addname = [];
      for (const key in this.compilecustomsx.nr.ts) {
        if (!this.compilecustomsx.nr.ts[key].id) {
          // console.log(this.compilecustomsx.nr.Items[key].n);
          this.compilecustomsx.addname.push(this.compilecustomsx.nr.ts[key].n);
        }
      }
      var s = "";
      this.compilecustomsx.chg = [];
      for (const ke in this.compileMaterial.customprop) {
        if (
          this.comperty_checkedCities[0] ==
          this.compileMaterial.customprop[ke].id
        ) {
          for (const ki in this.compileMaterial.customprop[ke].ts) {
            // console.log(this.compileMaterial.customprop[ke]);
            s = this.compileMaterial.customprop[ke].n;
            for (const key in this.compilecustomsx.nr.ts) {
              // console.log(this.compileMaterial.customprop[ke].Items[ki].n);
              // console.log(this.compilecustomsx.nr.Items[key].n);
              // console.log(this.compilecustomsx.nr.Items[key].n == this.compileMaterial.customprop[ke].Items[ki].n);
              if (
                this.compilecustomsx.nr.ts[key].id ==
                this.compileMaterial.customprop[ke].ts[ki].id
              ) {
                if (
                  this.compilecustomsx.nr.ts[key].n !=
                  this.compileMaterial.customprop[ke].ts[ki].n
                ) {
                  this.compilecustomsx.chg.push({
                    id: this.compilecustomsx.nr.ts[key].id,
                    n: this.compilecustomsx.nr.ts[key].n
                  });
                }
              }
            }
          }
        }
      }
      if (
        this.compilecustomsx.nr.n != s ||
        this.compilecustomsx.delid.length != 0 ||
        this.compilecustomsx.addname.length != 0 ||
        this.compilecustomsx.chg.length != 0
      ) {
        // this.$api.ERP.mat.requestmatchg_attr({
        //   id: this.checkedCities[0],
        //   attr_id: this.compilecustomsx.nr.id,
        //   attr_name: this.compilecustomsx.nr.n,
        //   del_dtl_items: this.compilecustomsx.delid,
        //   new_dtl_item_names: this.compilecustomsx.addname,
        //   chg_dtl_items: this.compilecustomsx.chg,
        // }).then(res => {
        //   console.log(res);
        //   if (res.code == 1) {
        //     this.refreshMaterialProperty()
        //     this.compiletrolprope = false
        //     this.$message({showClose: true, message: "操作成功", type: 'success'})
        //     this.comperty_isIndeterminate = false
        //     this.comperty_checkAll = false
        //     this.comperty_checkedCities = []
        //   } else {
        //     this.$message.warning(res.msg)
        //   }
        // })
      } else {
        this.compiletrolprope = false;
        this.$message({
          showClose: true,
          message: "操作成功",
          type: "success"
        });
      }
    },
    // 删除自定义属性
    delteperty() {
      // this.$api.ERP.mat.requestmatrm_attr({
      //   id: this.checkedCities[0],
      //   attr_ids: this.comperty_checkedCities,
      // }).then(res => {
      //   console.log(res);
      //   if (res.code == 1) {
      //     this.refreshMaterialProperty()
      //     this.comperty_isIndeterminate = false
      //     this.comperty_checkAll = false,
      //       this.comperty_checkedCities = []
      //     this.$message({showClose: true, message: "操作成功", type: 'success'})
      //   }
      // })
    },
    // 关闭编辑弹窗
    gaunbbjym() {
      this.redact = false;
      this.checkAll = false;
      this.checkedCities = [];
      this.isIndeterminate = false;
    },
    // 重试
    chdefrs() {
      if (this.srnr == "置为无效") {
        this.noneffective();
      } else if (this.srnr == "置为有效") {
        this.effective();
      } else if (this.srnr == "批量删除") {
        this.printerdel();
      }
    },
    // 同步
    synchronizon() {
      this.kzsfjy = true;
      var s = "";
      if (this.srnr == "置为无效") {
        s = 2;
      } else if (this.srnr == "置为有效") {
        s = 1;
      } else if (this.srnr == "批量删除") {
        s = 3;
      }
      var tid = [];
      var id = [];
      for (const iterator of this.cwsm.cs) {
        tid.push(iterator.tid);
        id.push(iterator.id);
      }
      this.$api.ERP.mat
        .requestmatob({
          op_status: Number(s),
          type_ids: tid,
          ids: id
        })
        .then(res => {
          if (res.code == 1) {
            for (const key in this.cwsm.cs) {
              this.cwsm.cs[key].jg = "成功";
            }
            this.refresh(this.$route.params.id);
            if (this.cwsm.ns.length < 1) {
              this.chdefrs();
            }
          } else if (res.code == 2) {
            for (const key in this.cwsm.cs) {
              for (const keys in res.data) {
                if (this.cwsm.cs[key].id == res.data[keys].id) {
                  this.cwsm.cs[key].jg = "失败";
                }
              }
            }
            for (const key in this.cwsm.cs) {
              if (this.cwsm.cs[key].jg == "---") {
                this.cwsm.cs[key].jg = "成功";
              }
            }
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 无效
    noneffective() {
      if (this.checkedCities.length > 0) {
        this.$api.ERP.mat
          .requestmatdisable({ ids: this.checkedCities })
          .then(res => {
            if (res.code == 1) {
              this.refresh(this.$route.params.id);
              this.weik();
              this.dialogFible = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
            } else if (res.code == 2) {
              this.dialogFible = true;
              this.kzsfjy = false;
              this.srnr = "置为无效";
              this.cwsm.ns = res.data.ns || [];
              for (const key in res.data.cs) {
                res.data.cs[key].jg = "---";
              }
              this.cwsm.cs = res.data.cs || [];
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行更改");
      }
    },
    // 有效
    effective() {
      if (this.checkedCities.length > 0) {
        this.$api.ERP.mat
          .requestmatenable({ ids: this.checkedCities })
          .then(res => {
            if (res.code == 1) {
              this.refresh(this.$route.params.id);
              this.weik();
              this.dialogFible = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
            } else if (res.code == 2) {
              this.dialogFible = true;
              this.kzsfjy = false;
              this.srnr = "置为有效";
              this.cwsm.ns = res.data.ns || [];
              for (const key in res.data.cs) {
                res.data.cs[key].jg = "---";
              }
              this.cwsm.cs = res.data.cs || [];
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行删除");
      }
    },
    // 删除
    printerdel() {
      if (this.checkedCities.length > 0) {
        this.$api.ERP.mat
          .requestmatdel({ ids: this.checkedCities })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.refresh(this.$route.params.id);
              this.weik();
              this.dialogFible = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
            } else if (res.code == 2) {
              this.dialogFible = true;
              this.kzsfjy = false;
              this.srnr = "批量删除";
              this.cwsm.ns = res.data.ns || [];
              for (const key in res.data.cs) {
                res.data.cs[key].jg = "---";
              }
              this.cwsm.cs = res.data.cs || [];
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行删除");
      }
    },

    // 打开批量导入弹窗
    DownloadBatch() {
      this.chooseTemplateStatus = 1;
      this.batchImport = true;
      if (!this.$refs) {
        // 清空列表
        this.$refs.ToLeadItem.clearFiles();
      }
    },
    // 下载批量导入模板
    DownloadTemplate() {
      // chooseTemplateStatus : 2:仅导入物料  3： 导入物料和收银商品
      const downLoadApi =
        this.chooseTemplateStatus == 2
          ? "requestmattpl"
          : "requestmatAndProTpl";
      this.$api.ERP.mat[downLoadApi]().then(res => {
        const url = window.URL.createObjectURL(
          new Blob([res], {
            type:
              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          })
        );
        // const url = window.URL.createObjectURL(new Blob([res],{type: '.xlsx'}))
        // console.log(url);
        const a = document.createElement("a"); //添加a标签
        document.body.appendChild(a);
        a.href = url;
        a.setAttribute("download", decodeURIComponent(res.fileName)); // 下载文件的名称及文件类型后缀
        a.click(); //点击标签
        document.body.removeChild(a); // 下载完成移除元素
        window.URL.revokeObjectURL(url); // 释放掉blob对象
      });
    },
    // 上传成功
    succeed(response, file, fileList) {
      console.log("成功", response);
      // 清空列表
      // this.$refs.ToLeadItem.clearFiles()
      //上传成功关掉蒙层
      this.loading.close();
      // console.log(response.data.ids);
      if (response.code == 1 || response.code == 2) {
        this.ImportData = [];
        var s = {};
        this.whetherForbidden = [];
        this.checkAlldata = false;
        this.isIndeterminatedata = false;
        this.checkedCitiesdata = [];

        // 有错误数据
        if (response.data.err_ids) {
          for (const key in response.data.ids) {
            s =
              this.chooseTemplateStatus == 2
                ? {
                    names: response.data.names[key] || "",
                    ids: response.data.ids[key] || "",
                    unit_names: response.data.unit_names[key] || "",
                    mat_one_cate_names:
                      response.data.mat_one_cate_names[key] || "",
                    mat_two_cate_names:
                      response.data.mat_two_cate_names[key] || "",
                    rtn_bottle: response.data.rtn_bottle[key] || ""
                  }
                : {
                    names: response.data.mat_names[key] || "",
                    ids: response.data.ids[key] || "",
                    unit_names: response.data.unit_names[key] || "",
                    mat_one_cate_names:
                      response.data.mat_one_cate_names[key] || "",
                    mat_two_cate_names:
                      response.data.mat_two_cate_names[key] || "",
                    prd_names: response.data.prd_names[key] || "",
                    prd_one_cate_names:
                      response.data.prd_one_cate_names[key] || "",
                    prd_two_cate_names:
                      response.data.prd_two_cate_names[key] || "",
                    prd_types: response.data.prd_types[key] || "",
                    prices: response.data.prices[key] || "",
                    // member_prices: response.data.member_prices[key] || "",
                    rtn_bottle: response.data.rtn_bottle[key] || ""
                  };

            const findIndex = response.data.err_ids.findIndex(
              item => item == s.ids
            );
            s.disabled = findIndex > -1;
            s.err_msgs = response.data.err_msgs[findIndex] || "";

            this.ImportData.push(s);
          }
          this.whetherForbidden = this.ImportData.map(item => item.disabled);

          var id = response.data.ids;

          for (var i = 0; i < response.data.ids.length; i++) {
            for (var j = 0; j < response.data.err_ids.length; j++) {
              if (id[i] == response.data.err_ids[j]) {
                id.splice(i, 1);
                i = i - 1;
              }
            }
          }
          this.checkedCitiesdata = id || [];
          if (id.length > 0) {
            this.isIndeterminatedata = true;
          }
          this.dataAnalysis = response.data.ids.length;
        } else {
          for (const key in response.data.ids) {
            this.whetherForbidden.push(false);
            this.checkedCitiesdata.push(response.data.ids[key] || "");
            this.isIndeterminatedata = false;
            this.checkAlldata = true;

            const s =
              this.chooseTemplateStatus == 2
                ? {
                    names: response.data.names[key] || "",
                    ids: response.data.ids[key] || "",
                    unit_names: response.data.unit_names[key] || "",
                    mat_one_cate_names:
                      response.data.mat_one_cate_names[key] || "",
                    mat_two_cate_names:
                      response.data.mat_two_cate_names[key] || "",
                    rtn_bottle: response.data.rtn_bottle[key] || ""
                  }
                : {
                    names: response.data.mat_names[key] || "",
                    ids: response.data.ids[key] || "",
                    unit_names: response.data.unit_names[key] || "",
                    mat_one_cate_names:
                      response.data.mat_one_cate_names[key] || "",
                    mat_two_cate_names:
                      response.data.mat_two_cate_names[key] || "",
                    prd_names: response.data.prd_names[key] || "",
                    prd_one_cate_names:
                      response.data.prd_one_cate_names[key] || "",
                    prd_two_cate_names:
                      response.data.prd_two_cate_names[key] || "",
                    prd_types: response.data.prd_types[key] || "",
                    prices: response.data.prices[key] || "",
                    // member_prices: response.data.member_prices[key] || "",
                    rtn_bottle: response.data.rtn_bottle[key] || ""
                  };
            this.ImportData.push(s);
          }
          // s.err_ids = ''
          // s.err_msgs = []
          this.dataAnalysis = response.data.ids.length;
        }
        // console.log(this.ImportData);
        // console.log(this.whetherForbidden);

        // this.$message({showClose:true,message:"导入成功",type:'success'})
        this.feedback = true;
        // console.log();
        // 清空列表
        this.$refs.ToLeadItem.clearFiles();
      } else {
        this.$message({ message: response.msg, type: "warning" });
      }
    },
    // 上传失败
    error(response, file, fileList) {
      console.log("失败");
      this.loading.close(); //上传失败关掉蒙层
      // console.log(response);
      // console.log(file);
      // console.log(fileList);
      this.$message({ message: "上传失败,请重新上传", type: "warning" });
      // 清空列表
      // this.$refs.ToLeadItem.clearFiles()
    },
    // 上传时
    progress(response, file, fileList) {
      console.log(process.env.NODE_ENV);
      console.log("上传");
      // 上传的时候打开蒙层
      const loading = this.$loading({
        lock: true,
        text: "上传中",
        spinner: "el-icon-loading",
        background: "rgba(0, 0, 0, 0.7)"
      });
      this.loading = loading;
    },
    // 重新导入
    resumes() {
      this.feedback = false;
      // 清空列表
      this.$refs.ToLeadItem.clearFiles();
    },
    // 控制批量导入全选或者全不选
    handleCheckAllChangedata(val) {
      if (val) {
        this.checkedCitiesdata = [];
        for (const key in this.ImportData) {
          if (!this.ImportData[key].err_msgs) {
            this.checkedCitiesdata.push(this.ImportData[key].ids);
          }
        }
      } else {
        this.checkedCitiesdata = [];
      }
      this.isIndeterminatedata = false;
    },
    // 控制批量导入单个选中
    handleCheckedCitiesChangedata(value) {
      // console.log(value);

      let checkedCount = value.length;
      this.checkAlldata = checkedCount === this.ImportData.length;
      this.isIndeterminatedata =
        checkedCount > 0 && checkedCount < this.ImportData.length;
      // console.log(this.checkedCities);
    },
    // 导入数据
    importDataHandle() {
      if (this.checkedCitiesdata.length > 0) {
        const s =
          this.chooseTemplateStatus == 2
            ? {
                ids: [],
                names: [],
                mat_one_cate_names: [],
                mat_two_cate_names: [],
                unit_names: [],
                rtn_bottle: []
              }
            : {
                ids: [], //        []int     数据序号
                mat_names: [], //  []string  存货物料名称
                mat_one_cate_names: [], // []string   存货物料一级分类名称
                mat_two_cate_names: [], // []string   存货物料二级分类名称
                unit_names: [], // []string   物料/商品单位名称
                rtn_bottle: [], // []string   空瓶回收,有/无
                prd_names: [], //  []string   收银商品名称
                prd_one_cate_names: [], // []string   收银商品一级分类名称
                prd_two_cate_names: [], // []string   收银商品二级分类名称
                prd_types: [], //  []string   收银商品类型 单品(主营) 单品(非主营) 单品(非主营分成) 花篮 小费 赔偿 联营
                prices: [], //     []string   收银商品单价
                // member_prices: [] // []string   收银商品会员单价
              };
        for (const i in this.whetherForbidden) {
          if (!this.whetherForbidden[i]) {
            for (const key in this.checkedCitiesdata) {
              if (this.checkedCitiesdata[key] == this.ImportData[i].ids) {
                s.ids.push(this.ImportData[i].ids);
                s.mat_one_cate_names.push(
                  this.ImportData[i].mat_one_cate_names
                );
                s.mat_two_cate_names.push(
                  this.ImportData[i].mat_two_cate_names
                );
                s.unit_names.push(this.ImportData[i].unit_names);
                s.rtn_bottle.push(this.ImportData[i].rtn_bottle);
                if (this.chooseTemplateStatus == 2) {
                  // 导入物料
                  s.names.push(this.ImportData[i].names);
                }
                if (this.chooseTemplateStatus == 3) {
                  // 导入物料和收银商品
                  s.mat_names.push(this.ImportData[i].names)
                  s.prd_names.push(this.ImportData[i].prd_names)
                  s.prd_one_cate_names.push(this.ImportData[i].prd_one_cate_names)
                  s.prd_two_cate_names.push(this.ImportData[i].prd_two_cate_names)
                  s.prd_types.push(this.ImportData[i].prd_types)
                  s.prices.push(this.ImportData[i].prices)
                  // s.member_prices.push(this.ImportData[i].member_prices)
                }
              }
            }
          }
        }
        const apiInterface = this.chooseTemplateStatus == 2 ? 'requestmatimp': 'requestmatAndMoneyimp'
        this.$api.ERP.mat[apiInterface](s).then(res => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.refresh(this.$route.params.id);
            this.$root.$emit('next') //调用父路由中刷新菜单
            this.feedback = false;
            this.batchImport = false;
            // batchImport
            // 清空列表
            this.$refs.ToLeadItem.clearFiles();
          } else {
            this.$message({
              showClose: true,
              message: res.msg,
              type: "warning"
            });
          }
        });
      } else {
        this.$message({
          message: "请选择一个物料再进行操作",
          type: "warning"
        });
      }
    },
    //获取焦点
    edit() {
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse.focus();
        console.log(this.$refs.selectsse);
      });
    }
  },
  computed: {
    http() {
      const matHttp =
        (process.env.NODE_ENV === "development"
          ? projectConfig[projectName]['development'] : projectConfig[projectName]['product']) + "/mat/imp_chk";
      const matAndMontyHttp =
        (process.env.NODE_ENV === "development"
          ? projectConfig[projectName]['development'] : projectConfig[projectName]['product']) + "/mat/imp_with_prd_chk";
      return this.chooseTemplateStatus == 2 ? matHttp : matAndMontyHttp;
    },

    watc() {
      return JSON.parse(JSON.stringify(this.classify));
    },
    newmerchand() {
      return JSON.parse(JSON.stringify(this.newmerchandise));
    },
    newmeMateriar() {
      return JSON.parse(JSON.stringify(this.newmerchandise.Materialunit));
    },
    compileMate() {
      return JSON.parse(JSON.stringify(this.compileMaterial));
    },
    compileMatMatere() {
      return JSON.parse(JSON.stringify(this.compileMaterial.Materialunit));
    },
    addbjpupss() {
      return JSON.parse(JSON.stringify(this.addbjpopup));
    }

    // compileMaterial
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
    // 监听路由变化
    $route: function() {
      console.log(this.$route.params.id);
      this.refresh(this.$route.params.id);
      this.weik();
    },
    // 监听每换一下分类商品也会换
    watc: {
      deep: true,
      handler: function(after, before) {
        if (after.stairfl != before.stairfl) {
          this.classify.Secondfl = 0;
          this.checkAll = false;
          this.checkedCities = [];
          this.isIndeterminate = false;
        }
        // console.log(after.stairfl != before.stairfl);
        if (after.Secondfl != before.Secondfl) {
          this.checkAll = false;
          this.checkedCities = [];
          this.isIndeterminate = false;
        }
        // console.log(after.stairSecond[after.stairfl].ss);
        if (after.stairSecond[after.stairfl]) {
          if (after.stairSecond[after.stairfl].ss) {
            this.pdddymy = true;
            this.refresh(this.$route.params.id);
          } else {
            this.pdddymy = false;
            // this.$message({showClose:true,message:"没有二级分类，请先创建二级分类", type: 'warning',})
            this.merchandise = [];
          }
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
        // 只让输入数字  限制小数点后有两位就不能输入了
        if (after.price) {
          var reg = /^[0-9]+(\.[0-9]{0,2})?$/;
          if (!reg.test(after.price)) {
            this.newmerchandise.price = before.price;
          }
        }
      }
    },
    // 根据所选单位添加比例
    newmeMateriar: {
      deep: true,
      handler: function(after, before) {
        // console.log(after[0]);
        // console.log(before[0]);

        var reg = /^[0-9]+(\.[0-9]{0,2})?$/;
        for (const key in this.newmerchandise.ListUnits) {
          for (const ke in after) {
            if (after[ke].id == this.newmerchandise.ListUnits[key].id) {
              this.newmerchandise.Materialunit[
                ke
              ].ratio = this.newmerchandise.ListUnits[key].us;
              // console.log(this.newmerchandise.ListUnits[key].ut);
              // console.log(this.newmerchandise.Materialunit[ke]);
              this.newmerchandise.Materialunit[
                ke
              ].ut = this.newmerchandise.ListUnits[key].ut;
            }
            if (after[ke].bp || "" == (before[ke] || {}).bp || "") {
              if (!reg.test(after[ke].bp)) {
                this.newmerchandise.Materialunit[ke].bp =
                  (before[ke] || {}).bp || "";
              }
            }
            if (after[ke].sp || "" == (before[ke] || {}).sp || "") {
              if (!reg.test(after[ke].sp)) {
                this.newmerchandise.Materialunit[ke].sp =
                  (before[ke] || {}).sp || "";
              }
            }
            // console.log(!reg.test(after[ke].bp));
          }
        }
        // console.log(after[0]);
        // console.log(before[0]);
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
    }
  }
};
</script>
<style>
/* 错误2 */
.Single .diagrgeesfelogFor .el-dialog {
  width: 720px;
  border-left: 1px solid #f9f9f9;
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.Single .diagrgeesfelogFor .wwent {
  color: #ce4153;
  font-size: 14px;
  margin: 20px 0px 20px 20px;
  display: flex;
  align-items: center;
}

.Single .diagrgeesfelogFor .wentlb {
  margin-left: 20px;
  width: 640px;
}

.Single .diagrgeesfelogFor .zhuixiaoi {
  width: 100%;
}

.Single .diagrgeesfelogFor .zhuixiaoi .limiting {
  max-height: 280px !important;
  overflow-y: auto !important;
}

.Single .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1),
.Single .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
  width: 50px;
}

.Single .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2),
.Single .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
  width: 320px;
}

.Single .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3),
.Single .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
  width: 200px;
}

.Single .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2),
.Single .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
  width: 520px;
}

/* 无效颜色 */
.Single .diagrgeesfelogFor .el-button--primary.is-disabled,
.Single .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
  background-color: #1f2846;
  color: #4e505a;
  border-color: #1f2846;
}

/* 靠右 */
.Single .el-dialog {
  margin: 0px 0px 0px auto !important;
  height: 100%;
  position: relative;
}

.Single .el-dialog__body {
  padding: 0px 0px 30px 20px;
  overflow-y: scroll !important;
  width: 100%;
  width: calc(100% - 40px);
  height: calc(100% - 160px);
  max-height: calc(100% - 160px);
  margin: 0;
}

.Single .el-dialog {
  border-left: 1px solid #f9f9f9;
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.Single .el-dialog__footer {
  position: absolute;
  width: 100%;
  bottom: 0;
  right: 0;
  display: flex;
  justify-content: center;
}

.Single {
  width: calc(100% - 40px);
  height: calc(100% - 40px);
  padding: 20px 30px;
}

.Single .dialogPrinter .el-form {
  padding-top: 10px !important;
}

/* 必填 */
.Single .mandatory {
  color: #40404e;
  width: 140px;
  text-align: right;
  /* padding-top: 10px; */
  line-height: 34px;
}

.Single .controlling {
  width: 230px !important;
  line-height: 40px;
}

.Single .reqfieldsd {
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
.Single .between .zhuixiaoi .el-checkbox__label {
  color: #40404e;
}

.Single .between .zhuixiaoi .mmodity .el-checkbox__label {
  font-size: 12px;
}

/* 一级分类下没二级分类的时候 */
.Single .between {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-top: 170px;
  padding-right: 400px;
}

.Single .between img {
  width: 100px;
  height: 100px;
}

.Single .between .period {
  margin-top: 30px;
  color: #a3a3a3;
  font-size: 18px;
}

/* 选中状态颜色背景边框 */
.Single .el-radio-button__orig-radio:checked + .el-radio-button__inner {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #6a9eff !important;
  color: #6a9eff;
}

/* 表格无数据时展示 */
.Single .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.Single .nodata img {
  width: 60px;
  height: 60px;
}

.Single .nodata .hint {
  line-height: 36px;
  font-size: 13px !important;
}

.Single .drag-list .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.Single .drag-list .nodata img {
  width: 60px;
  height: 60px;
}

.Single .drag-list .nodata .hint {
  font-size: 13px !important;
}

/* 限制一级分类二级分类宽带 */
.Single .stairastrict {
  width: 1000px;
}

/* 给一级分类二级分类加外边距和圆角 */
.Single .el-radio-button {
  margin-right: 6px;
  margin-bottom: 6px;
  /* overflow: hidden; */
  /* border: 1px solid #f5f5f5; */
}

.Single .el-radio-button__inner {
  border-radius: 4px !important;
}

/* 去除瑕疵 */
.Single .el-radio-button__orig-radio:checked + .el-radio-button__inner {
  box-shadow: none;
}

/*去除双击文字、input等，出现的蓝色底色*/
.container {
  -moz-user-select: none; /*火狐*/
  -webkit-user-select: none; /*webkit浏览器*/
  -ms-user-select: none; /*IE10*/
  /*-khtml-user-select:none;!*早期浏览器*!*/
  user-select: none;
}

.Single-headline {
  font-size: 30px;
  font-weight: bold;
  color: #40404e;
}

.Single-controller {
  /*margin-top: 30px;*/
  height: 54px;
  width: 1400px;
  background-color: #e5e5e5;
  display: flex;
  align-items: center;
}

.Single table {
  border-collapse: collapse;
  /* border: solid 1px #f5f5f5; */
  color: #40404e;
}

.Single .el-checkbox__label {
  color: #40404e;
}

/* .Single th:nth-of-type(1){
      width: 100px;
    }
     .Single th:nth-of-type(2){
      width: 300px !important;
    } */

.Single .List-move {
  transition: transform 0.2s;
}

.Single .tolead .choose .el-dialog {
  width: 400px !important;
}

.Single .tolead .el-dialog {
  width: 720px !important;
}

.Single .check {
  color: #40404e;
}

.Single .el-dialog .el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
}

.Single .el-dialog {
  background-color: #f9f9f9;
}

.Single .el-input__inner {
  background-color: transparent;
  color: #40404e;
}

.Single .el-dialog__title,
.Single .el-dialog__headerbtn .el-dialog__close,
.Single .el-form-item__label {
  color: #1a1a21;
  display: flex;
  align-items: center;
}

.Single .el-form-item {
  display: flex;
  margin: 0;
}

.Single .el-table th.el-table__cell.is-leaf {
  background-color: #2a2b34;
  color: #40404e;
  border-bottom: 1px solid #f5f5f5;
  border-right: 1px solid #f5f5f5;
}

/* 改变多选框背景颜色和上下间距 */
.Single .el-checkbox-group {
  display: flex;
  align-items: flex-end;
  justify-content: left;
}

.Single .el-checkbox__input {
  background-color: rgba(0, 0, 0, 0);
}

.Single .el-dialog {
  width: 30vw;
}

.Single .has-gutter {
  border: 1px solid #f5f5f5;
}

.Single .el-table--border {
  border-top: 1px solid #f5f5f5;
  border-left: 1px solid #f5f5f5;
}

.Single .el-table__body:nth-of-type(odd) {
  background-color: #f9f9f9;
  color: #40404e;
}

.Single .el-table__body:nth-of-type(even) {
  background-color: #f5f5f5;
  color: #40404e;
}

.Single .el-table__empty-block {
  background-color: #e5e5e5 !important;
}

.Single .el-table__empty-text {
  color: #40404e;
}

.Single .el-table__body tr:hover > td {
  background-color: #3c3d46 !important;
}

.Single .el-table__body tr.current-row > td {
  background-color: #3c3d46 !important;
}

.Single .el-table__body td.el-table__cell {
  border-bottom: 1px solid #f5f5f5;
  border-right: 1px solid #f5f5f5;
}

.Single .el-table--border,
.Single .el-table--group {
  border-top: 1px solid #f5f5f5;
  border-left: 1px solid #f5f5f5;
}

.Single .el-table--border::after,
.Single .el-table--group::after,
.Single .el-table::before {
  background-color: #f5f5f5;
}

.Single .el-table .success-row {
  background-color: #3c3d46 !important;
}

.Single .el-table__header-wrapper .el-table_1_column_1 {
  border-left: 2px solid #f5f5f5 !important;
}

.Single .is-scrolling-none .el-table_1_column_1 {
  border-left: 2px solid #f5f5f5 !important;
}

.Single .el-input-number__decrease,
.Single .el-input-number__increase {
  background-color: rgba(0, 0, 0, 0);
}

.Single .el-radio__label {
  color: #40404e;
}

.Single .el-input__inner {
  background-color: transparent !important;
}
</style>
<style>
/* 一级分类和二级分类文字颜色更改 */
.Single .stairfl {
  display: flex;
  /* align-items: baseline; */
  margin: 15px 0;
}

.Single .stairfl .classification {
  width: 100px;
  color: #40404e;
  margin-right: 20px;
  font-size: 16px;
  padding-top: 10px;
}

.Single .stairfl .fl {
  color: #ce4153;
  margin: 0 11px;
  height: 42px;
  line-height: 42px;
}

/* .Single .stairfl div:nth-of-type(2){ */
/* color: #40404e;
            margin-right: 20px; */
/* } */
/* 更改单选框颜色 */
.Single .el-radio-button__inner {
  background-color: rgba(0, 0, 0, 0);
  color: #40404e;
  border: 1px solid #f5f5f5;
  font-size: 14px;
}

.Single .el-radio-button:first-child .el-radio-button__inner {
  border-left: 1px solid #f5f5f5;
}

/* 更改按钮字体大小 */
.Single .el-button {
  font-size: 14px;
}

/* 新建商品 */
.Single .dialogPrinter .el-dialog {
  /* width: 50vw !important;
            min-width: 620px !important;
            max-width:620px !important; */
  width: 720px;
}

.Single .dialogPrinter .el-dialog__body {
  padding: 10px;
}

.Single .dialogPrinter .Materialunit {
  width: 1060px;
  border: 1px solid #40404e;
  padding: 10px;
}

.Single .dialogPrinter .biaot {
  font-size: 24px;
  color: #40404e;
  text-align: center;
  margin-bottom: 10px;
}

.Single .dialogPrinter .compa-tib {
  color: #40404e;
}

.Single .dialogPrinter .rial-unit {
  display: flex;
}

.Single .dialogPrinter .rial-unit .miaos {
  line-height: 34px;
  width: 630px;
  margin-left: 20px;
  color: #40404e;
}

.Single .dialogPrinter .el-button--mini,
.el-button--small {
  font-size: 14px !important;
}

.Single .compatibil {
  margin-bottom: 10px;
}

.Single .compatibility {
  display: flex;
  /* align-items: center; */
  margin-bottom: 5px;
}

/* 列表配置 */
.Single .dialogPrinter table {
  width: 1060px;
  margin-top: 10px;
  font-size: 14px;
  /* overflow: hidden; */
  display: inline-block;
}

.Single .dialogPrinter table .drag-list {
  display: inline-block;
  width: 100% !important;
}

.Single .dialogPrinter table .mmodity tr th {
  height: 40px;
  line-height: 40px;
  text-align: left;
  padding-left: 20px;
  background-color: #2d2e38;
  font-size: 14px;
  font-weight: 400;
}

.Single .dialogPrinter table .limiting .drag-list td {
  height: 40px;
  line-height: 40px;
  text-align: left;
  padding-left: 20px;
  font-size: 14px;
  font-weight: 400;
}

.Single .dialogPrinter table .limiting .drag-list {
  border-top: solid 1px #f5f5f5;
  display: block;
  display: flex;
}

.Single .dialogPrinter table .mmodity {
  width: 100%;
  display: block;
}

.Single .dialogPrinter table .mmodity tr {
  background-color: #2d2e38;
  display: flex;
  border-top: solid 1px #f5f5f5;
}

.Single .dialogPrinter table .limiting {
  overflow-y: scroll !important;
  max-height: 200px !important;
  border-bottom: solid 1px #f5f5f5;
  display: block;
}

/* 单位 */
.Single .dialogPrinter .Mater-unit .drag-list .nodata {
  height: 180px !important;
}

.Single .dialogPrinter .Mater-unit .drag-list td {
  line-height: 39px !important;
  display: flex;
  align-items: center;
}

.Single .dialogPrinter .Mater-unit .lans {
  color: #409eff;
}

.Single .dialogPrinter .Mater-unit .lans:hover {
  color: #66b1ff;
}

.Single .dialogPrinter .Mater-unit .drag-list td:nth-of-type(1),
.Single .dialogPrinter .Mater-unit .mmodity th:nth-of-type(1) {
  width: 70px;
}

.Single .dialogPrinter .Mater-unit .drag-list td:nth-of-type(2),
.Single .dialogPrinter .Mater-unit .mmodity th:nth-of-type(2) {
  width: 200px;
}

.Single .dialogPrinter .Mater-unit .drag-list td:nth-of-type(3),
.Single .dialogPrinter .Mater-unit .mmodity th:nth-of-type(3) {
  width: 100px;
}

.Single .dialogPrinter .Mater-unit .drag-list td:nth-of-type(4),
.Single .dialogPrinter .Mater-unit .mmodity th:nth-of-type(4) {
  width: 150px;
}

.Single .dialogPrinter .Mater-unit .drag-list td:nth-of-type(5),
.Single .dialogPrinter .Mater-unit .mmodity th:nth-of-type(5) {
  width: 150px;
}

/* Mater-unit */
/* 扩展属性 */
.Single .dialogPrinter .annkz {
  display: flex;
  justify-content: center;
}

.Single .dialogPrinter .extend-unit {
  margin-top: 10px;
  font-size: 14px;
  /* overflow: hidden; */
  display: inline-block;
}

.Single .dialogPrinter .extend-unit .drag-list .nodata {
  height: 180px !important;
}

.Single .dialogPrinter .extend-unit .drag-list td:nth-of-type(1),
.Single .dialogPrinter .extend-unit .mmodity th:nth-of-type(1) {
  width: 70px;
}

.Single .dialogPrinter .extend-unit .drag-list td:nth-of-type(2),
.Single .dialogPrinter .extend-unit .mmodity th:nth-of-type(2) {
  width: 200px;
}

.Single .dialogPrinter .extend-unit .drag-list td:nth-of-type(3),
.Single .dialogPrinter .extend-unit .mmodity th:nth-of-type(3) {
  width: 380px;
}

/* 自定义属性 */
.Single .user-defined .el-dialog {
  width: 720px !important;
}

.Single .user-defined .explain {
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

.Single .user-defined .el-form {
  padding-top: 20px !important;
}

.Single .user-defined .attribute {
  /* width: 90%; */
  width: 500px;
  display: flex;
  flex-direction: column;
}

.Single .user-defined .attribute > div {
  display: flex;
}

.Single .user-defined .el-input {
  width: 230px;
  margin-bottom: 10px;
}

.Single .user-defined .el-form-item__content {
  /* width: 100%; */
  display: flex;
  margin-bottom: 10px;
}

.Single .user-defined .compatibil .compatibility {
  align-items: flex-start;
}

.Single .user-defined .compatibil .compatibility .required {
  padding-top: 15px;
}

.Single .user-defined .compatibil .compatibility .el-button {
  width: 40px;
  height: 40px;
  margin-left: 10px;
}

/* 编辑商品 */
.Single .dialogPrinter .needattention {
  /* margin-bottom: 10px; */
  font-size: 12px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Single .dialogPrinter .fenge {
  box-sizing: border-box;
  width: 100%;
  /* border: 1px solid rgb(61, 61, 61); */
  border: none;
  padding: 10px 0;
  margin-bottom: 10px;
}

.Single .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(1),
.Single .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(1) {
  width: 70px;
}

.Single .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(2),
.Single .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(2) {
  width: 170px;
}

.Single .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(3),
.Single .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(3) {
  width: 70px;
}

.Single .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(4),
.Single .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(4) {
  width: 140px;
}

.Single .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(5),
.Single .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(5) {
  width: 140px;
}

.Single .dialogPrinter .fenge .Materialunit .drag-list td:nth-of-type(6),
.Single .dialogPrinter .fenge .Materialunit .mmodity th:nth-of-type(6) {
  width: 70px;
}

.Single .dialogPrinter .fenge .Mater-unit .el-button + .el-button {
  margin-left: 0;
}

/* 编辑 添加物料单位 */
.Single .editaddunit .el-dialog {
  width: 720px !important;
}

.Single .editaddunit .requimeiytgy {
  color: #40404e;
  font-size: 20px;
}

.Single .required {
  width: 60px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Single .layouts {
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

/* 下拉框 */
.el-select-dropdown__wrap {
  background-color: #f5f5f5;
}

.el-select-dropdown__empty {
  background-color: #f9f9f9;
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
  color: #40404E;
}

.el-select-dropdown {
  border: 1px solid #f5f5f5;
}

/* 上传文件 拖拽文件到目标上面 */
.Single .el-upload-dragger {
  background-color: #f9f9f9;
  border: 1px dashed #555763;
}

.Single .el-upload-dragger.is-dragover {
  /* background-color: #f5f5f5; */
  background-color: rgba(32, 158, 255, 0.06);
  /* border: 1px dashed var(--el-color-primary); */
  border: 1px dashed #5873bd;
}

.Single .upload-demo {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.Single .el-upload-list__item:hover {
  background-color: #f5f5f5;
}

.Single .el-upload-list__item-name [class^="el-icon"] {
  color: #40404e;
}

.Single .el-upload-list__item-name {
  color: #40404e;
}

.Single .el-icon-close {
  color: #40404e;
}

/* 反馈信息 */
.Single .feedback .el-dialog {
  width: 1280px !important;
}

.Single .feedback .juzhong {
  max-width: 1200px;
  overflow-x: scroll;
}

.Single .feedback table {
  overflow-x: auto !important;
  width: 100%;
  border-top: solid 1px #f5f5f5;
  border-collapse: collapse;
  color: #40404e;
}

.Single .feedback table thead {
  width: 100%;
  display: block;
}

.Single .feedback table tbody {
  width: 100%;
  height: calc(100vh - 300px);
  display: block;
  max-height: 600px !important;
  border-bottom: solid 1px #f5f5f5;
  overflow-y: scroll !important;
}

.Single .feedback table thead tr {
  background-color: #f5f5f5;
  display: flex;
}

.Single .feedback .feedback-check:nth-of-type(1) {
  color: #ce4153;
  font-size: 12px;
  margin-top: 15px;
}

.Single .feedback .feedback-check:nth-of-type(2) {
  color: #40404e;
  font-size: 20px;
  margin: 15px 0;
  font-weight: 600;
}

.Single .feedback .juzhong thead tr th {
  height: 40px;
  line-height: 40px;
  text-align: left;
  padding-left: 20px;
  font-size: 14px;
  font-weight: 600;
  color: #40404e;
}

.Single .feedback .juzhong thead tr th .el-checkbox__label{
  font-size: 14px;
  font-weight: 600;
}

.Single .juzhong .drag-lists {
  display: flex;
  align-items: center;
  border-top: solid 1px #f5f5f5;
}

.Single .feedback .juzhong .drag-lists td {
  min-height: 40px;
  line-height: 40px;
  text-align: left;
  padding-left: 20px;
  font-size: 14px;
  font-weight: 400;
  display: inline-block;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(1),
.Single .feedback .juzhong thead th:nth-of-type(1) {
  width: 100px;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(2),
.Single .feedback .juzhong thead th:nth-of-type(2) {
  width: 200px;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(3),
.Single .feedback .juzhong thead th:nth-of-type(3) {
  width: 120px;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(4),
.Single .feedback .juzhong thead th:nth-of-type(4) {
  width: 120px;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(5),
.Single .feedback .juzhong thead th:nth-of-type(5) {
  width: 100px;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(6),
.Single .feedback .juzhong thead th:nth-of-type(6) {
  width: 100px;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(7),
.Single .feedback .juzhong thead th:nth-of-type(7) {
  width: 80px;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(8),
.Single .feedback .juzhong thead th:nth-of-type(8) {
  width: 130px;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(9),
.Single .feedback .juzhong thead th:nth-of-type(9) {
  width: 130px;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(10),
.Single .feedback .juzhong thead th:nth-of-type(10) {
  width: 300px;
}

.Single .feedback .juzhong .drag-lists td:nth-of-type(9) div {
  margin: 3px 0;
}

.Single .juzhong .drag-lists:nth-of-type(odd) {
  background-color: #f9f9f9;
}

.Single .juzhong .drag-lists:nth-of-type(even) {
  background-color: #f5f5f5;
}

/* .juzhong{ */
/* display: flex;
            justify-content: center; */
/* } */
</style>
<style>
/* 列表 */
.Single .zhuixiaoi {
  width: 1400px;
  border-collapse: collapse;
  color: #40404e;
}

/* .Single .zhuixiaoi thead,.Single  .zhuixiaoi thead tr,.Single .zhuixiaoi tbody tr{
        width: 100% !important;
    } */
.Single .zhuixiaoi .drag-list {
  display: inline-block;
  width: 100% !important;
}

.Single .zhuixiaoi .mmodity tr th {
  height: 40px;
  line-height: 40px;
  text-align: left;
  padding-left: 20px;
  font-size: 14px;
  font-weight: 600;
  color: #40404e;
}

.Single .zhuixiaoi .mmodity tr th .el-checkbox__label {
  font-size: 14px;
  font-weight: 600;
}

.Single .zhuixiaoi .limiting .drag-list td {
  height: 40px;
  line-height: 40px;
  text-align: left;
  padding-left: 20px;
  font-size: 14px;
  font-weight: 400;
}

.Single .zhuixiaoi .limiting .drag-list {
  border-top: solid 1px #f5f5f5;
  display: block;
  display: flex;
}

.Single .zhuixiaoi .mmodity {
  width: 100%;
  display: block;
}

.Single .zhuixiaoi .mmodity tr {
  background-color: #f5f5f5;
  display: flex;
}

.Single .zhuixiaoi .limiting {
  border-bottom: solid 1px #f5f5f5;
  overflow-y: auto !important;
  max-height: 540px;
  display: block;
}

/* 物料列表 */
.Single .drag-list td:nth-of-type(1),
.Single .mmodity th:nth-of-type(1) {
  width: 70px;
}

.Single .drag-list td:nth-of-type(2),
.Single .mmodity th:nth-of-type(2) {
  width: 300px;
}

.Single .drag-list td:nth-of-type(3),
.Single .mmodity th:nth-of-type(3) {
  width: 170px;
}

.Single .drag-list td:nth-of-type(4),
.Single .mmodity th:nth-of-type(4) {
  width: 170px;
}

.Single .drag-list td:nth-of-type(5),
.Single .mmodity th:nth-of-type(5) {
  width: 170px;
}

.Single .drag-list td:nth-of-type(6),
.Single .mmodity th:nth-of-type(6) {
  width: 150px;
}

.Single .drag-list td:nth-of-type(7),
.Single .mmodity th:nth-of-type(7) {
  width: 150px;
}

.Single .drag-list td:nth-of-type(8),
.Single .mmodity th:nth-of-type(8) {
  width: 75px;
}

.Single .drag-list:nth-of-type(odd) {
  background-color: #f9f9f9;
}

.Single .drag-list:nth-of-type(even) {
  background-color: #f5f5f5;
}

.el-radio {
  display: flex;
  align-items: center;
}

.Single .meisfgr {
  width: 100%;
  overflow-x: scroll !important;
}

.drag-list-check {
  /* background: rgba(39, 52, 82, 0.5) !important; */
}

.el-dialog__wrapper{
  height: 100vh;
}
</style>