function isElement(node, tagName) {
  return node?.type === 'element' && node.tagName === tagName;
}

function hasClass(node, className) {
  const classes = node?.properties?.className;
  return Array.isArray(classes) && classes.includes(className);
}

function tableColumnCount(table) {
  const head = table.children?.find((child) => isElement(child, 'thead'));
  const row = head?.children?.find((child) => isElement(child, 'tr'));
  return row?.children?.filter((child) => isElement(child, 'th')).length ?? 0;
}

function tableWrapper(table) {
  const classes = ['table-scroll'];
  if (tableColumnCount(table) >= 4) classes.push('table-scroll--wide');

  return {
    type: 'element',
    tagName: 'div',
    properties: {
      className: classes,
      tabIndex: 0,
      role: 'region',
      ariaLabel: 'Scrollable data table',
    },
    children: [table],
  };
}

function transformChildren(parent, insideTableScroll = false) {
  if (!parent?.children) return;

  parent.children = parent.children.map((child) => {
    if (isElement(child, 'table') && !insideTableScroll) return tableWrapper(child);

    const childIsTableScroll = isElement(child, 'div') && hasClass(child, 'table-scroll');
    transformChildren(child, insideTableScroll || childIsTableScroll);
    return child;
  });
}

export default function rehypeTableScroll() {
  return (tree) => transformChildren(tree);
}
