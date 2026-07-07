function normalizeText(value) {
  return value === undefined || value === null ? '' : value.toString().toLowerCase();
}

function isActivePerson(person) {
  if (!person) return false;

  const status = person.status;
  if (status === undefined || status === null || status === '') return true;
  if (status === '有效') return true;
  if (status === '无效') return false;

  return Number(status) === 1;
}

function matchesKeyword(person, keyword, matchMode) {
  if (!keyword) return true;

  const fields = [
    person && person.code,
    person && person.name,
    person && person.namePy,
  ].map(normalizeText);

  return fields.some((field) => {
    return matchMode === 'startsWith' ? field.startsWith(keyword) : field.includes(keyword);
  });
}

function normalizeIds(ids) {
  if (!Array.isArray(ids)) return [];
  return ids.map((id) => Number(id)).filter((id) => !Number.isNaN(id));
}

function getActivePersonOptions(people, query, options) {
  const list = Array.isArray(people) ? people : [];
  const opts = options || {};
  const keyword = normalizeText(query).trim();
  const excludedIds = normalizeIds(opts.excludeIds);
  const matchMode = opts.matchMode === 'startsWith' ? 'startsWith' : 'includes';

  return list
    .filter(isActivePerson)
    .filter((person) => !excludedIds.includes(Number(person.id)))
    .filter((person) => matchesKeyword(person, keyword, matchMode));
}

module.exports = {
  getActivePersonOptions,
  isActivePerson,
};
