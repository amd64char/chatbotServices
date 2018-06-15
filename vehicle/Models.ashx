<%@ WebHandler Language="C#" Class="Models" %>

using System;
using System.Web;
using Newtonsoft.Json;
using System.Collections.Generic;

public class Models : IHttpHandler {
    
    
    public void ProcessRequest (HttpContext context) {
        
        context.Response.ContentType = "application/json";
        context.Response.ContentEncoding = System.Text.Encoding.UTF8;
        context.Response.Expires = -1;
        context.Response.Cache.SetAllowResponseInBrowserHistory(true);

        string _apiKey = "";
        string _make = "";
        string _year = "";
        string _segment = "";

        List<string> requestErrors = new List<string> {};

        if (context.Request["make"] != null) {
            _make = context.Request["make"];
        } else {
            requestErrors.Add("vehicle make is required.");
        }
        if (context.Request["year"] != null) {
            _year = context.Request["year"];
        } else {
            requestErrors.Add("vehicle year is required.");
        }
        if (context.Request["key"] != null) {
            _apiKey = context.Request["key"];
            if (Account.isValidKey(_apiKey) != true) {
                requestErrors.Add("api key is invalid.");
            }
        } else {
            requestErrors.Add("api key is required.");
        }


        if (requestErrors.Count > 0) {
            string jsonErrors = JsonConvert.SerializeObject(requestErrors, Formatting.None);
            string jsonError = Newtonsoft.Json.JsonConvert.SerializeObject(new {
                error = jsonErrors
            }, Newtonsoft.Json.Formatting.Indented);
            context.Response.Write(jsonError);
            return;
        }

        System.Data.DataTable dtDealers = getModels(_make, _year, _segment);
        string jsonDealers = JsonConvert.SerializeObject(dtDealers, Formatting.Indented);

        context.Response.Write(jsonDealers);
    }

    /// <summary>
    /// Returns a list of available Models based on Make and Year.
    /// </summary>
    /// <param name="sMake">Must be one of "Ford" or "Lincoln". This is a mandatory parameter.</param>
    /// <param name="sYear">Model Year for vehicle being queried. This is a mandatory parameter. Format as "2018".</param>
    /// <param name="sSegment">Must be one of "car", "suv", "truck" or "crossover". This is an optional parameter. When provided, it acts as a filter.</param>
    /// <returns>JSON Array</returns>
    private static System.Data.DataTable getModels(string sMake, string sYear, string sSegment) {
        var dtModels = new System.Data.DataTable();
        dtModels.Columns.Add("make", Type.GetType("System.String"));
        dtModels.Columns.Add("model", Type.GetType("System.String"));
        dtModels.Columns.Add("year", Type.GetType("System.String"));
        dtModels.Columns.Add("segment", Type.GetType("System.String"));
        dtModels.Columns.Add("url", Type.GetType("System.String"));

        string _exitURL = "";
        string _exitSection = "";
        string _regionDefault = System.Configuration.ConfigurationManager.AppSettings["defaultRegion"].ToString();
        string _utmSource = System.Configuration.ConfigurationManager.AppSettings["defaultUTMSource"].ToString();
        string _utmMedium = System.Configuration.ConfigurationManager.AppSettings["defaultUTMMedium"].ToString();
        string _utmCampaign = System.Configuration.ConfigurationManager.AppSettings["defaultUTMCampaign"].ToString();

        string jUrl = "https://www.servicesus.ford.com/products/Segments/?make=" + sMake;
        if (System.String.IsNullOrEmpty(sSegment) == false) {
            jUrl = jUrl + "&segment=" + sSegment; 
        }

        var webClient = new System.Net.WebClient();
        string xmlResponse = webClient.DownloadString(jUrl);

        var xmlDoc = new System.Xml.XmlDocument();
        xmlDoc.LoadXml(xmlResponse);

        System.Xml.XmlNode root = xmlDoc.DocumentElement;
        System.Xml.XmlNodeList nodeList = root.SelectNodes("//Model[@Year='" + sYear + "']");

        foreach (System.Xml.XmlNode model in nodeList) {
            System.Data.DataRow dRow = dtModels.NewRow();
            string _make = model.Attributes["Make"].Value.ToString();
            string _model = model.Attributes["Model"].Value.ToString();
            string _year = model.Attributes["Year"].Value.ToString();
            string _segment = "";
            if (System.String.IsNullOrEmpty(sSegment)) {
                _segment = model.SelectSingleNode("../../name").InnerText.ToString();
            } else {
                _segment = sSegment.ToLower();
            }
            
            _exitSection = "compare-cars-trucks-suvs/side-by-side-comparison/" + _year + "-" + _make.ToLower() + "-" + _model.Replace(" ", "-").ToLower();
            _exitURL = "https://www.buyfordrightnow.com?page=/" + _regionDefault + "/" + _exitSection + "&utm_source=" + _utmSource + "&utm_medium=" + _utmMedium + "&utm_campaign=" + _utmCampaign;
                
            dRow["make"] = _make;
            dRow["model"] = _model;
            dRow["year"] = _year;
            dRow["segment"] = _segment;
            dRow["url"] = _exitURL;
            dtModels.Rows.Add(dRow);
        }
        dtModels.AcceptChanges();

        return dtModels;
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}