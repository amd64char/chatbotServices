<%@ WebHandler Language="C#" Class="Dealers" %>

using System;
using System.Web;
using Newtonsoft.Json;
using System.Collections.Generic;

public class Dealers : IHttpHandler {

    public void ProcessRequest (HttpContext context) {

        context.Response.ContentType = "application/json";
        context.Response.ContentEncoding = System.Text.Encoding.UTF8;
        context.Response.Expires = -1;
        context.Response.Cache.SetAllowResponseInBrowserHistory(true);

        string _apiKey = "";
        string _zipCode = "";
        int _maxDealers = 0;

        List<string> requestErrors = new List<string> {};

        if (context.Request["postalCode"] != null) {
            _zipCode = context.Request["postalCode"];
        } else {
            requestErrors.Add("postalCode is required.");
        }
        if (context.Request["maxDealers"] != null) {
            _maxDealers = Convert.ToInt32(context.Request["maxDealers"]);
        } else {
            requestErrors.Add("maxDealers is required.");
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

        System.Data.DataTable dtDealers = getDealers(_zipCode, _maxDealers);
        string jsonDealers = JsonConvert.SerializeObject(dtDealers, Formatting.Indented);

        context.Response.Write(jsonDealers);
    }

    /// <summary>
    /// Returns a list of closest dealer based on zipCode.
    /// </summary>
    /// <param name="sZipCode">5 digit USPS Postal Code. This is a mandatory parameter.</param>
    /// <param name="iHowMany">Maximum numbers of dealers to be returned in the result. This is a mandatory parameter.</param>
    /// <returns>JSON Array</returns>
    private static System.Data.DataTable getDealers(string sZipCode, int iHowMany) {
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
        string jUrl = "https://www.fake.ford.service.com/dealer/Dealers?make=Ford&radius=100&maxDealers=" + iHowMany + "&postalCode=" + sZipCode;
        string xmlResponse = webClient.DownloadString(jUrl);

        var xmlDoc = new System.Xml.XmlDocument();
        xmlDoc.LoadXml(xmlResponse);

        System.Xml.XmlNode root = xmlDoc.DocumentElement;
        System.Xml.XmlNodeList nodeList = root.SelectNodes("//Dealer");

        int dealerCount = 0;
        foreach (System.Xml.XmlNode dealer in nodeList) {
            if (dealerCount >= iHowMany) {
                break;
            }
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
