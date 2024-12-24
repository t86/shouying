// 创建新文件处理数据过滤
self.onmessage = function(e) {
  const { cardList, key, id } = e.data;
  const filtered = filterCards(cardList, key, id);
  self.postMessage(filtered);
}; 