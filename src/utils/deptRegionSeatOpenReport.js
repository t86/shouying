function formatDepartmentName(departmentName) {
  const value = departmentName == null ? '' : String(departmentName);
  let indent = 0;
  let nameStart = 0;

  while (nameStart < value.length && /\s/.test(value[nameStart])) {
    indent += value[nameStart] === '\u3000' ? 2 : 1;
    nameStart += 1;
  }

  return {
    name: value.slice(nameStart),
    indent,
  };
}

function isTotalRow(item) {
  return Boolean(item) && Number(item.id) === 0;
}

module.exports = {
  formatDepartmentName,
  isTotalRow,
};
