//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.ReadabilityParserAPI : GLib.Object {

    private Soup.Session m_session;
	private Soup.Message m_message_soup;
    private Json.Parser m_parser;
	private Json.Object m_root_object;
    private string m_contenttype;
    private string m_token;

    public ReadabilityParserAPI(string url)
    {
        m_token = settings_tweaks.get_string("parser-api-key");
        m_session = new Soup.Session();
		m_contenttype = "application/x-www-form-urlencoded";
		m_parser = new Json.Parser ();
		m_message_soup = new Soup.Message ("GET", "https://www.readability.com/api/content/v1/parser?url=" + url + "&token=" + m_token);

		if(settings_tweaks.get_boolean("do-not-track"))
			m_message_soup.request_headers.append("DNT", "1");
    }

    public int process()
    {
        m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return ConnectionError.NO_RESPONSE;

		try{
			m_parser.load_from_data((string)m_message_soup.response_body.flatten().data);
		}
		catch (Error e) {
			logger.print(LogMessage.ERROR, "Could not load response to Message to ttrss");
			logger.print(LogMessage.ERROR, e.message);
			return ConnectionError.NO_RESPONSE;
		}

        m_root_object = m_parser.get_root().get_object();

        if(m_root_object.has_member("content"))
		{
            return ConnectionError.SUCCESS;
		}

        return ConnectionError.UNKNOWN;
    }

    public string getAuthor()
    {
        if(m_root_object.has_member("author"))
		{
			return m_root_object.get_string_member("author");
		}
        else
        {
            return _("no Author");
        }
    }

    public string getTitle()
    {
        if(m_root_object.has_member("title"))
		{
			return m_root_object.get_string_member("title");
		}
        else
        {
            return _("no Title");
        }
    }

    public string getPreview()
    {
        if(m_root_object.has_member("excerpt"))
		{
			return m_root_object.get_string_member("excerpt");
		}
        else
        {
            return _("no Preview");
        }
    }

    public string getContent()
    {
        if(m_root_object.has_member("content"))
		{
			return m_root_object.get_string_member("content");
		}
        else
        {
            return _("no content");
        }
    }
}
