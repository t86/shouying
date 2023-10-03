
function flatten(array, ss) {
    let result = []

    array.forEach(item => {
      if (item[ss]) {
        result = result.concat(item[ss])
        result = result.concat(flatten(item[ss], ss))
      }
    })

    return result
  }

export default { flatten }