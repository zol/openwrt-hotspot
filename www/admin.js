function popitup(anc)
{
  var url = anc.href;
  var h   = anc.getAttribute ('h');
  var w   = anc.getAttribute ('w');
  
  newwindow=window.open(url,'name',"height=" + h + ",width=" + w);
  if (window.focus) {newwindow.focus()}
  return false;
}

function dopopups()
{
  var x = document.getElementsByTagName('a');
  for (var i=0;i<x.length;i++)
  {
    if (x[i].getAttribute('type') == 'popup')
    {
      x[i].onclick = function () {
        return popitup(this);
      }
      x[i].title += ' (Popup)';
    }
  }
}

function check_addtime(form)
{
  if(form.days.value < 0 || form.days.value > 365)
  {
    alert("You must enter a day between 1 and 365.");
    return false;
  }
  
  if(form.hours.value < 0 || form.hours.value > 24)
  {
    alert("You must enter an hour between 1 and 24.");
    return false;
  }
  
  if(form.days.minutes < 0 || form.days.minutes > 60)
  {
    alert("You must enter minutes between 1 and 60.");
    return false;
  }

  if(form.days.value == "" && 
     form.hours.value == "" &&
     form.minutes.value == "")
  {
    alert("You must enter a time to add to this token.");
    return false;
  }

  if(form.identifier.value.length > 20)
  {
    alert("You cannot enter a name longer than 20 characters");
    return false;
  }

  return true;
}

function gotourl(url)
{
  location.href=url;
}
