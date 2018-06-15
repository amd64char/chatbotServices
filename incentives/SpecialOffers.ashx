<%@ WebHandler Language="C#" Class="SpecialOffers" %>

using System;
using System.Web;
using Newtonsoft.Json;
using System.Collections.Generic;

public class SpecialOffers : IHttpHandler {
    
    public void ProcessRequest (HttpContext context) {
        context.Response.ContentType = "application/json";
        context.Response.ContentEncoding = System.Text.Encoding.UTF8;
        context.Response.Expires = -1;
        context.Response.Cache.SetAllowResponseInBrowserHistory(true);

        string _apiKey = "";
        string _zipCode = "";
        string _make = "";
        string _model = "";
        string _year = "";

        List<string> requestErrors = new List<string> {};

        if (context.Request["postalCode"] != null) {
            _zipCode = context.Request["postalCode"];
        } else {
            requestErrors.Add("postalCode is required.");
        }
        if (context.Request["make"] != null) {
            _make = context.Request["make"];
        } else {
            requestErrors.Add("vehicle make is required.");
        }
        if (context.Request["model"] != null) {
            _model = context.Request["model"];
        } else {
            requestErrors.Add("vehicle model is required.");
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

        string sOfferURL = getOffersLink(_zipCode, _make, _model, _year);
        string jsonURL = Newtonsoft.Json.JsonConvert.SerializeObject(new {
            url = sOfferURL
        }, Newtonsoft.Json.Formatting.Indented);

        context.Response.Write(jsonURL);
    }

    /// <summary>
    /// Returns Special Offers for a given vehicle based on zipCode.
    /// </summary>
    /// <param name="sZipCode">5 digit USPS Postal Code. This is a mandatory parameter.</param>
    /// <param name="sMake">The make or band. Must be one of "Ford" or "Lincoln". This is a mandatory parameter.</param>
    /// <param name="sModel">The model name. Example. "F-150". This is a mandatory parameter.</param>
    /// <param name="sYear">The model year for vehicle being queried. Example. "2018". This is a mandatory parameter.</param>
    /// <returns>JSON Array</returns>
    private static string getOffersLink(string sZipCode, string sMake, string sModel, string sYear) {

        string _exitURL = "";
        string _exitSection = "";
        string _regionDefault = System.Configuration.ConfigurationManager.AppSettings["defaultRegion"].ToString();
        string _utmSource = System.Configuration.ConfigurationManager.AppSettings["defaultUTMSource"].ToString();
        string _utmMedium = System.Configuration.ConfigurationManager.AppSettings["defaultUTMMedium"].ToString();
        string _utmCampaign = System.Configuration.ConfigurationManager.AppSettings["defaultUTMCampaign"].ToString();
        
        switch (sModel.ToString().ToLower()) {
            //Cars
            case "fusion":
                _exitSection = "incentives-offers/ford-fusion-offers";
                break;
            case "fiesta":
                _exitSection = "incentives-offers/ford-fiesta-offers";
                break;
            case "focus":
                _exitSection = "incentives-offers/ford-focus-offers";
                break;
            case "mustang":
                _exitSection = "incentives-offers/ford-mustang-offers";
                break;
            case "taurus":
                _exitSection = "incentives-offers/ford-taurus-offers";
                break;   
            //Trucks    
            case "f-150":
                _exitSection = "incentives-offers/ford-f-150-offers";
                break;
            case "f150":
                _exitSection = "incentives-offers/ford-f-150-offers";
                break;
            case "superduty":
                _exitSection = "incentives-offers/ford-super-duty-offers";
                break;
            case "super-duty":
                _exitSection = "incentives-offers/ford-super-duty-offers";
                break;
            case "transit":
                _exitSection = "incentives-offers/ford-transit-offers";
                break;
            case "transit-connect":
                _exitSection = "incentives-offers/ford-transit-connect-offers";
                break;
            case "transitconnect":
                _exitSection = "incentives-offers/ford-transit-connect-offers";
                break;
            //SUVs
            case "ecosport":
                _exitSection = "incentives-offers/ford-ecosport-offers";
                break;
            case "escape":
                _exitSection = "incentives-offers/ford-escape-offers";
                break;
            case "edge":
                _exitSection = "incentives-offers/ford-edge-offers";
                break;
            case "flex":
                _exitSection = "incentives-offers/ford-flex-offers";
                break;
            case "explorer":
                _exitSection = "incentives-offers/ford-explorer-offers";
                break;
            case "expedition":
                _exitSection = "incentives-offers/ford-expedition-offers";
                break;
                
        }

        _exitURL = "https://www.buyfordrightnow.com?page=/" + _regionDefault + "/" + _exitSection + "&utm_source=" + _utmSource + "&utm_medium=" + _utmMedium + "&utm_campaign=" + _utmCampaign;
        
        return _exitURL;
    }   
    
    private static System.Data.DataTable getOffers(string sZipCode, string sMake, string sModel, string sYear) {
        var dtDealer = new System.Data.DataTable();
        dtDealer.Columns.Add("paCode", Type.GetType("System.String"));
        dtDealer.Columns.Add("name", Type.GetType("System.String"));
        dtDealer.Columns.Add("address", Type.GetType("System.String"));
        dtDealer.Columns.Add("city", Type.GetType("System.String"));
        dtDealer.Columns.Add("province", Type.GetType("System.String"));
        dtDealer.Columns.Add("postalCode", Type.GetType("System.String"));
        dtDealer.Columns.Add("country", Type.GetType("System.String"));
        dtDealer.Columns.Add("phone", Type.GetType("System.String"));
        dtDealer.Columns.Add("fdafId", Type.GetType("System.String"));
        dtDealer.Columns.Add("email", Type.GetType("System.String"));
        dtDealer.Columns.Add("latitude", Type.GetType("System.String"));
        dtDealer.Columns.Add("longitude", Type.GetType("System.String"));
        dtDealer.Columns.Add("url", Type.GetType("System.String"));

        var webClient = new System.Net.WebClient();
        string jUrl = "https://www.servicesus.ford.com/incentives/SpecialOffers?make=" + sMake + "&model=" + sModel + "&year=" + sYear + "&postalCode=" + sZipCode;
        string xmlResponse = webClient.DownloadString(jUrl);

        var xmlDoc = new System.Xml.XmlDocument();
        xmlDoc.LoadXml(xmlResponse);

        System.Xml.XmlNode root = xmlDoc.DocumentElement;
        System.Xml.XmlNodeList nodeList = root.SelectNodes("//Dealer");

        int dealerCount = 0;
        foreach (System.Xml.XmlNode dealer in nodeList) {
            System.Data.DataRow dRow = dtDealer.NewRow();
            dRow["paCode"] = dealer["PACode"].InnerText.ToString();
            dRow["name"] = dealer["Name"].InnerText.ToString();
            dRow["address"] = dealer.SelectSingleNode("Address/Street1").InnerText.ToString();
            dRow["city"] = dealer.SelectSingleNode("Address/City").InnerText.ToString();
            dRow["province"] = dealer.SelectSingleNode("Address/State").InnerText.ToString();
            dRow["postalCode"] = dealer.SelectSingleNode("Address/PostalCode").InnerText.ToString();
            dRow["country"] = dealer.SelectSingleNode("Address/Country").InnerText.ToString();
            dRow["phone"] = dealer["Phone"].InnerText.ToString();
            dRow["url"] = dealer["URL"].InnerText.ToString();
            dRow["email"] = dealer["Email"].InnerText.ToString();
            try {
                dRow["fdafId"] = dealer["GeoKey"].InnerText.ToString().Split('|').GetValue(1).ToString();
            } catch {
                dRow["fdafId"] = "";
            }
            dRow["latitude"] = dealer["Latitude"].InnerText.ToString();
            dRow["longitude"] = dealer["Longitude"].InnerText.ToString();
            dtDealer.Rows.Add(dRow);
            dealerCount++;
        }
        dtDealer.AcceptChanges();

        return dtDealer;
    }

    public bool IsReusable {
        get {
            return false;
        }
    }

}