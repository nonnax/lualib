#!/usr/bin/env luajit
-- id$ nonnax sun jul 28 20:40:00 2024
-- https://github.com/nonnax
-- utils.lua
local utils = {}

-- function to perform string interpolation
function utils.interpolate(str, subs)
    table.foreach(subs, function(k, v)
        str = str:gsub(string.format('{%s}', k), tostring(v))  -- ensure the value is a string
    end)
    return str
end

function utils.format(str, subs)
    return string.format(str, unpack(subs))
end

utils.f=utils.interpolate

-- getmetatable("").__mod=utils.interpolate
-- getmetatable("").__mul=utils.format

-- function to generate pagination html
function utils.generate_paginator(current_page, total_pages, link_window)
    local link_window = link_window or 20
    local paginator_html = {}
    local half_window = math.floor(link_window / 2)
    local start_page = math.max(1, current_page - half_window)
    local end_page = math.min(total_pages, current_page + half_window)

    -- adjust start and end page to ensure the window size is consistent
    if current_page <= half_window then
        end_page = math.min(total_pages, start_page + link_window - 1)
    elseif current_page > total_pages - half_window then
        start_page = math.max(1, end_page - link_window + 1)
    end

    current_page = math.min(current_page, total_pages)
    current_page = math.max(current_page, 1)

    table.insert(paginator_html, "<div class='pagination'>")

    -- previous button
    if current_page > 1 then
        table.insert(paginator_html, utils.interpolate("<a href='page_{prev_page}.html'>&laquo; prev</a>", {prev_page = current_page - 1}))
    else
        table.insert(paginator_html, "<span class='disabled'>&laquo; prev</span>")
    end

    -- page number links
    for page = start_page, end_page do
        if page == current_page then
            table.insert(paginator_html, utils.interpolate("<a class='active' href='page_{page}.html'>{page}</a>", {page = page}))
        else
            table.insert(paginator_html, utils.interpolate("<a href='page_{page}.html'>{page}</a>", {page = page}))
        end
    end

    -- next button
    if current_page < total_pages then
        table.insert(paginator_html, utils.interpolate("<a href='page_{next_page}.html'>next &raquo;</a>", {next_page = current_page + 1}))
    else
        table.insert(paginator_html, "<span class='disabled'>next &raquo;</span>")
    end

    table.insert(paginator_html, "</div>")

    return table.concat(paginator_html, "\n")
end

-- function to generate pagination table
function utils.paginator(current_page, total_pages, link_window)
    local link_window = link_window or 20
    local pages = {}
    local half_window = math.floor(link_window / 2)
    local start_page = math.max(1, current_page - half_window)
    local end_page = math.min(total_pages, current_page + half_window)

    -- adjust start and end page to ensure the window size is consistent
    if current_page <= half_window then
        end_page = math.min(total_pages, start_page + link_window - 1)
    elseif current_page > total_pages - half_window then
        start_page = math.max(1, end_page - link_window + 1)
    end

    current_page = math.max(math.min(current_page, total_pages), 1)


    -- previous button
    if current_page > 1 then
        table.insert(pages,  {page = current_page - 1})
    else
        table.insert(pages, {page = false})
    end

    -- page number links
    for page = start_page, end_page do
        if page == current_page then
            table.insert(pages, {page = page, active=true})
        else
            table.insert(pages, {page = page})
        end
    end

    -- next button
    if current_page < total_pages then
        table.insert(pages, {page = current_page + 1})
    else
        table.insert(pages, {page = false})
    end

    return pages
end

function utils.sample_paginator(current_page, total_pages)
  local pages= u.paginator(current_page, total_pages)
  local buff={}
  for i, v in pairs(pages) do
    if v.page then
      if v.active then
        table.insert(buff, "/{v} class='active'" % {v=v.page})
      else
        table.insert(buff, "/{v}" % {v=v.page})
      end
    elseif v.prev then
      table.insert(buff, "/{v} (prev)" % {v=v.prev_page or 1})
    elseif v.next then
      table.insert(buff, "/{v} (next)" % {v=v.next_page or total_pages})
    end
  end
  return table.concat(buff, "\n")
end


-- pattern to match open tags
local open_tag_pattern = "<%s*([%w]+)(.-)%s*>"

-- pattern to match close tags
local close_tag_pattern = "</%s*([%w]+)%s*>"

-- pattern to match self-closing tags
local self_closing_pattern = "<%s*([%w]+)(.-)%s*/>"

-- function to extract tags
function extract_tags(html)
    local tags = {}

    -- find open tags
    for tag_name, attributes in html:gmatch(open_tag_pattern) do
        table.insert(tags, {type = "open", name = tag_name, attributes = attributes})
    end

    -- find close tags
    for tag_name in html:gmatch(close_tag_pattern) do
        table.insert(tags, {type = "close", name = tag_name})
    end

    -- find self-closing tags
    for tag_name, attributes in html:gmatch(self_closing_pattern) do
        table.insert(tags, {type = "self-closing", name = tag_name, attributes = attributes})
    end

    return tags
end

function HTML()
    -- usage:
    -- h = html()
    -- div = h("<div class='pagination'>")
    --   div.open()
    --    h.innerhtml"html/text here"
    --    p = h("<p>")
    --     h.innerhtml(u.f("<{tag} class='red'>breaking news</{tag}>", {tag='em'}))
    --    p.close()
    --   div.close()
    -- div.close()

    local self={stack={}}
    function self.tag(str)
        -- any valid tag, inner_html or text
        table.insert(self.stack, str)
        local tag_env = {
            otag = str:match(open_tag_pattern)
        }
        local matcher = tag_env.otag ~= nil
        local matched_tag = {}
        -- reuse open tag
        function matched_tag.open()
            if matcher then
                table.insert(self.stack, "<{otag}>" % tag_env)
            end
        end
        -- add matching closing tag. reusable anywhere
        function matched_tag.close()
            if matcher then
                table.insert(self.stack, "</{otag}>" % tag_env)
            end
        end
        return matched_tag
    end

    local mt={}
    -- produce html doc string
    function mt.__tostring(t)
        return table.concat(t.stack, "\n")
    end
    -- instance_call() shortcut to self.tag
    function mt.__call(t, str)
        return t.tag(str)
    end
    setmetatable(self, mt)

    return self
end

function utils.indexer(page_number, items_per_page, max_items)
    local max_limit = math.ceil(max_items / items_per_page)
    local page_number = math.min(page_number, max_limit)
    local start_index = (page_number - 1) * items_per_page + 1
    local end_index = start_index + items_per_page - 1

    if end_index > max_items then
        end_index = max_items
        start_index = math.max(1, end_index - items_per_page + 1)
    end

    return start_index, end_index
end

function utils.make_range(pageNumber, itemsPerPage, maxPageNumber)
    local startIndex, endIndex = utils.indexer(pageNumber, itemsPerPage, maxPageNumber)
    local r = {}
    for i=startIndex, endIndex do
      table.insert(r, i)
    end
    return r
end

function utils.chunker(t, i, chunksize)
      if chunksize >= #t then return t end
      local chunk = {}
      for j = i, i + chunksize - 1 do
          table.insert(chunk, t[j])
      end
      -- if the chunk is smaller than `chunksize`,
      -- collect a chunk starting from the last `chunksize` elements
      if #chunk < chunksize then
        chunk = {}
        for j = math.max(#t - chunksize + 1, 1), #t do
            table.insert(chunk, t[j])
        end
      end
      return chunk
end

function utils.enclose_page(t, max_item)
     local page=t
     if page[1]>1 then
        table.insert(page, 1, page[1]-1)
     else
        table.insert(page, 1, 1)
     end

     if page[#page] < max_item then
        table.insert(page, page[1]+1)
     else
        table.insert(page, max_item)
     end
     return page
end

-- local str = 'str{},str2{str3{}},str4,str5{a{},b{}}'
-- for m in str:gsub('%b{}', function(b) return b:gsub(',', '\0') end):gmatch'[^,]+' do
--    m = m:gsub('%z', ',')
--    print(m)
-- end

return utils
