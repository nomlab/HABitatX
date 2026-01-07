import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tableBody", "hiddenField"]

  connect() {
    console.log("EditableTableController connected");
    this.headers = Array.from(this.element.querySelectorAll("thead th"))
      .slice(0, -1)
      .map(th => th.textContent.trim().toLowerCase());
  }

  addRow() {
    console.log("addRow called");
    const row = document.createElement("tr");

    this.headers.forEach(() => {
      const td = document.createElement("td");
      td.contentEditable = "true";
      td.innerText = "";
      row.appendChild(td);
    });

    const actionTd = document.createElement("td");
    const deleteBtn = document.createElement("button");
    deleteBtn.type = "button";
    deleteBtn.textContent = "Delete";
    deleteBtn.className = "button";
    deleteBtn.setAttribute("data-action", "click->editable-table#deleteRow");
    actionTd.appendChild(deleteBtn);
    row.appendChild(actionTd);

    this.tableBodyTarget.appendChild(row);
  }

  deleteRow(event) {
    console.log("deleteRow called");
    event.target.closest("tr").remove();
  }

  updateDslInfo(event) {
    console.log("updateDslInfo called");
    const data = [];
    const rows = this.tableBodyTarget.querySelectorAll("tr");
    console.log("rows", rows);

    for (let row of rows) {
      const cells = row.querySelectorAll("td");
      const obj = {};
      let hasEmpty = false;

      this.headers.forEach((header, i) => {
        const value = cells[i]?.textContent.trim();
        if (!value) hasEmpty = true;
        obj[header] = value;
      });

      if (hasEmpty) {
        event.preventDefault();
        alert("すべてのセルを入力してください（空欄があります）");
        return;
      }

      data.push(obj);
    }

    this.hiddenFieldTarget.value = JSON.stringify(data);
    console.log("Hidden field value:", this.hiddenFieldTarget.value);
  }
}
