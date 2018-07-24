#CASGEM DATA SCRAPE

import selenium
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select

chromedriver = "C:\\Users\\jglasskatz\\Desktop\\chromedriver.exe"
browser = webdriver.Chrome(chromedriver)
browser.get('https://www.casgem.water.ca.gov/OSS/')

user = browser.find_element_by_id("txtUserName_text")
pasw = browser.find_element_by_id("txtPassword_text")

user.send_keys("jglasskatz@lbl.gov")
pasw.send_keys("Biltong1")

browser.find_element_by_name("btnLogin").click()

browser.find_element_by_id("ctl00_lnkPublicReports").click()

browser.find_element_by_link_text("Report of Wells").click()

county = browser.find_element_by_id("ctl00_CASGEMBody_rblCriteria_3")

county.click()

name = "ctl00_CASGEMBody_lbCounty_i"
browser.find_element_by_id("ctl00_CASGEMBody_chkCASGEM").click()
browser.find_element_by_id("ctl00_CASGEMBody_chkVoluntary").click()
for n in range(1,60):
    cou = browser.find_element_by_id(name + str(n))
    cou.click()
    browser.find_element_by_name("ctl00$CASGEMBody$btnRunReport").click()
    dropdown = Select(browser.find_element_by_id("ctl00_CASGEMBody_wellsReportViewer_ReportToolbar_ExportGr_FormatList_DropDownList"))
    dropdown.select_by_visible_text("CSV (comma delimited)")
    browser.find_element_by_id("ctl00_CASGEMBody_wellsReportViewer_ReportToolbar_ExportGr_Export").click()
