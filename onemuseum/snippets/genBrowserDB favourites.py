                    # if row['Star'] == 1
                        <td class="col-1 float-right">
                            <a href="{{ url_for('users.favourite', entity=entity, guid=guid) }}"
                                style="cursor: copy">
                                <img src="{{ url_for('static', filename='img/staryellow.png') }}"
                                     id="row-{{row.guid}}"
                                     onclick="{{ url_for('users.favourite', entity=entity, guid=guid) }}"
                                     style="width:24px; height:24px" />
                            </a>
                        </td>
                    # else
                        <td class="col-1 float-right"
                            onclick="{{ url_for('users.favourite', entity=entity, guid=guid) }}"
                            style="cursor: copy">
                            <img src="{{ url_for('static', filename='img/starempty.png') }}"
                                    id="row-{{row.guid}}"
                                    onclick="{{ url_for('users.favourite', entity=entity, guid=guid) }}"
                                    style="width:24px; height:24px" />
                        </th>
                    # endif
